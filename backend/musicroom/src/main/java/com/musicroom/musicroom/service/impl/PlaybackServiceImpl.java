package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.PlaylistEntryDto;
import com.musicroom.musicroom.dto.VoteDto;
import com.musicroom.musicroom.dto.websocket.PlaybackMessage;
import com.musicroom.musicroom.entity.*;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.exception.UnauthorizedException;
import com.musicroom.musicroom.repository.*;
import com.musicroom.musicroom.service.PlaybackService;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.*;
import java.util.concurrent.*;

/**
 * Server-side playback engine.
 *
 * The server is the single source of truth for what is playing.
 * Once an event is started:
 *   1. The first track in the queue is broadcast as PLAY_TRACK to all listeners.
 *   2. A scheduled task fires after the track's duration to auto-advance.
 *   3. The finished track is deleted from the DB, and the next track plays.
 *   4. No PAUSE / STOP commands are accepted — music cannot be stopped.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PlaybackServiceImpl implements PlaybackService {

    private final EventRepository eventRepo;
    private final EventPlaylistRepository playlistRepo;
    private final VoteRepository voteRepo;
    private final EventInviteRepository inviteRepo;
    private final SimpMessagingTemplate messagingTemplate;
    private final TransactionTemplate transactionTemplate;

    private final ScheduledExecutorService scheduler =
            Executors.newScheduledThreadPool(4);

    /** eventId -> currently scheduled auto-advance future */
    private final Map<UUID, ScheduledFuture<?>> scheduledAdvances = new ConcurrentHashMap<>();

    /** eventId -> ID of the track entry currently playing */
    private final Map<UUID, UUID> currentlyPlaying = new ConcurrentHashMap<>();

    /** Set of events that have been started */
    private final Set<UUID> activeEvents = ConcurrentHashMap.newKeySet();

    /** eventId -> timestamp in millis when the current track started playing */
    private final Map<UUID, Long> trackStartTimes = new ConcurrentHashMap<>();

    @PreDestroy
    public void shutdown() {
        scheduler.shutdownNow();
    }

    @Override
    @Transactional
    public void startEvent(UUID eventId, UUID userId) {
        Event event = eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found"));

        // Only owner or editor can start the event
        boolean isOwner = event.getOwner().getId().equals(userId);
        if (!isOwner) {
            Optional<EventInvite> inviteOpt = inviteRepo.findByEventIdAndUserId(eventId, userId);
            if (inviteOpt.isEmpty() || !"admin".equalsIgnoreCase(inviteOpt.get().getRole())) {
                throw new UnauthorizedException("Only the event owner or editors can start playback");
            }
        }

        if (activeEvents.contains(eventId)) {
            log.info("Event {} is already playing, ignoring start request", eventId);
            return;
        }

        activeEvents.add(eventId);
        log.info("Event {} started by user {}", eventId, userId);

        // Play the first track
        playNextTrack(eventId);
    }

    @Override
    public boolean isEventPlaying(UUID eventId) {
        return activeEvents.contains(eventId);
    }

    @Override
    public Map<String, Object> getPlaybackStatus(UUID eventId) {
        boolean isPlaying = activeEvents.contains(eventId);
        if (!isPlaying) {
            return Map.of("isPlaying", false);
        }

        Long startTime = trackStartTimes.get(eventId);
        long positionMs = startTime != null ? (System.currentTimeMillis() - startTime) : 0L;

        // Clamp positionMs to track's duration if available
        UUID entryId = currentlyPlaying.get(eventId);
        if (entryId != null) {
            Optional<EventPlaylistEntry> entryOpt = playlistRepo.findById(entryId);
            if (entryOpt.isPresent()) {
                Track track = entryOpt.get().getTrack();
                if (track != null && track.getDurationMs() != null) {
                    positionMs = Math.min(positionMs, track.getDurationMs().longValue());
                }
            }
        }

        Map<String, Object> status = new HashMap<>();
        status.put("isPlaying", true);
        status.put("positionMs", positionMs);
        return status;
    }

    @Override
    public void onPlaylistChanged(UUID eventId) {
        if (!activeEvents.contains(eventId)) {
            return;
        }

        // If the event is active but nothing is currently playing (queue was empty),
        // try to play the next track
        UUID currentEntryId = currentlyPlaying.get(eventId);
        if (currentEntryId == null) {
            log.info("Event {} playlist changed and nothing playing, attempting to play next", eventId);
            playNextTrack(eventId);
        }
    }

    @Override
    public void stopEvent(UUID eventId) {
        activeEvents.remove(eventId);
        currentlyPlaying.remove(eventId);
        trackStartTimes.remove(eventId);
        ScheduledFuture<?> future = scheduledAdvances.remove(eventId);
        if (future != null) {
            future.cancel(false);
        }
        log.info("Event {} playback stopped", eventId);
    }

    /**
     * Core logic: find the first track in the sorted queue, broadcast it, schedule auto-advance.
     * Uses TransactionTemplate to ensure a Hibernate session is available even when called
     * from the scheduled thread pool.
     */
    private void playNextTrack(UUID eventId) {
        try {
            transactionTemplate.executeWithoutResult(status -> {
                doPlayNextTrack(eventId);
            });
        } catch (Exception e) {
            log.error("Error playing next track for event {}", eventId, e);
        }
    }

    /**
     * The actual playNextTrack logic, executed inside a transaction.
     */
    private void doPlayNextTrack(UUID eventId) {
        // Use eager-fetch query to avoid LazyInitializationException
        List<EventPlaylistEntry> entries = playlistRepo.findByEventIdWithTrackEager(eventId);

        // Robust sort logic:
        if (!entries.isEmpty()) {
            UUID currentPlayingId = currentlyPlaying.get(eventId);
            if (currentPlayingId != null) {
                // A track is currently playing. Keep it at index 0.
                EventPlaylistEntry playingEntry = null;
                List<EventPlaylistEntry> remaining = new ArrayList<>();
                for (EventPlaylistEntry entry : entries) {
                    if (entry.getId().equals(currentPlayingId)) {
                        playingEntry = entry;
                    } else {
                        remaining.add(entry);
                    }
                }

                // Sort remaining by votes desc, then suggestedAt asc
                remaining.sort((a, b) -> {
                    int voteCompare = Integer.compare(b.getVoteCount(), a.getVoteCount());
                    if (voteCompare != 0) return voteCompare;
                    return a.getSuggestedAt().compareTo(b.getSuggestedAt());
                });

                entries = new ArrayList<>();
                if (playingEntry != null) {
                    entries.add(playingEntry);
                }
                entries.addAll(remaining);
            } else {
                // No track is currently playing. Sort the ENTIRE list by votes desc, then suggestedAt asc
                entries = new ArrayList<>(entries);
                entries.sort((a, b) -> {
                    int voteCompare = Integer.compare(b.getVoteCount(), a.getVoteCount());
                    if (voteCompare != 0) return voteCompare;
                    return a.getSuggestedAt().compareTo(b.getSuggestedAt());
                });
            }
        }

        if (entries.isEmpty()) {
            log.info("Event {} queue is empty, waiting for new tracks", eventId);
            currentlyPlaying.remove(eventId);
            trackStartTimes.remove(eventId);

            // Broadcast QUEUE_EMPTY so clients know nothing is playing
            PlaybackMessage emptyMsg = new PlaybackMessage();
            emptyMsg.setCommand("QUEUE_EMPTY");
            messagingTemplate.convertAndSend("/topic/event/" + eventId + "/playback", emptyMsg);
            return;
        }

        EventPlaylistEntry firstEntry = entries.get(0);
        Track track = firstEntry.getTrack();
        currentlyPlaying.put(eventId, firstEntry.getId());
        trackStartTimes.put(eventId, System.currentTimeMillis());

        // Build the audioUrl from Audius
        String audioUrl = "https://discoveryprovider.audius.co/v1/tracks/"
                + track.getExternalId() + "/stream?app_name=MusicRoomApp";

        String suggestedByName = firstEntry.getSuggestedBy() != null
                ? firstEntry.getSuggestedBy().getDisplayName() : "";

        // Broadcast PLAY_TRACK to all listeners
        PlaybackMessage playMsg = new PlaybackMessage();
        playMsg.setTrackId(track.getExternalId());
        playMsg.setTitle(track.getTitle());
        playMsg.setArtist(track.getArtist());
        playMsg.setCoverUrl(track.getCoverUrl() != null ? track.getCoverUrl() : "");
        playMsg.setAudioUrl(audioUrl);
        playMsg.setSuggestedByName(suggestedByName);
        playMsg.setCommand("PLAY_TRACK");
        playMsg.setPositionMs(0L);

        messagingTemplate.convertAndSend("/topic/event/" + eventId + "/playback", playMsg);
        log.info("Event {} now playing: \"{}\" by {} (duration: {}ms)",
                eventId, track.getTitle(), track.getArtist(), track.getDurationMs());

        // Also broadcast EVENT_STARTED status
        Map<String, Object> statusPayload = new HashMap<>();
        statusPayload.put("type", "EVENT_STARTED");
        statusPayload.put("isPlaying", true);
        statusPayload.put("currentTrackId", track.getExternalId());
        messagingTemplate.convertAndSend("/topic/event/" + eventId + "/updates", statusPayload);

        // Schedule auto-advance after track duration
        int durationMs = track.getDurationMs() != null ? track.getDurationMs() : 180_000; // default 3 min
        // Add a small buffer (2 seconds) for network/processing
        long delayMs = durationMs + 2000L;

        // Cancel any existing scheduled advance
        ScheduledFuture<?> existing = scheduledAdvances.remove(eventId);
        if (existing != null) {
            existing.cancel(false);
        }

        ScheduledFuture<?> future = scheduler.schedule(
                () -> advanceTrack(eventId, firstEntry.getId()),
                delayMs,
                TimeUnit.MILLISECONDS
        );
        scheduledAdvances.put(eventId, future);

        log.info("Event {} auto-advance scheduled in {}ms", eventId, delayMs);
    }

    /**
     * Called when a track's duration has elapsed.
     * Removes the finished track and plays the next one.
     * Uses TransactionTemplate to ensure proper Hibernate session from scheduled threads.
     */
    public void advanceTrack(UUID eventId, UUID finishedEntryId) {
        if (!activeEvents.contains(eventId)) {
            log.info("Event {} is no longer active, skipping advance", eventId);
            return;
        }

        UUID currentEntryId = currentlyPlaying.get(eventId);
        if (currentEntryId == null || !currentEntryId.equals(finishedEntryId)) {
            log.info("Event {} track mismatch on advance (expected {} but current is {}), skipping",
                    eventId, finishedEntryId, currentEntryId);
            return;
        }

        try {
            // Delete the finished track inside a transaction
            transactionTemplate.executeWithoutResult(status -> {
                Optional<EventPlaylistEntry> entryOpt = playlistRepo.findById(finishedEntryId);
                if (entryOpt.isPresent()) {
                    playlistRepo.delete(entryOpt.get());
                    playlistRepo.flush();
                    log.info("Event {} removed finished track {}", eventId, finishedEntryId);

                    // Clear the currently playing map for this event since it finished
                    currentlyPlaying.remove(eventId);

                    // Broadcast the updated playlist
                    broadcastPlaylistUpdate(eventId);
                }
            });

            // Play the next track (also wrapped in its own transaction)
            playNextTrack(eventId);

        } catch (Exception e) {
            log.error("Error advancing track for event {}", eventId, e);
            // Try again after a short delay
            scheduler.schedule(() -> playNextTrack(eventId), 3, TimeUnit.SECONDS);
        }
    }

    /**
     * Broadcast the current playlist state to all clients.
     */
    private void broadcastPlaylistUpdate(UUID eventId) {
        try {
            // Use eager-fetch query to avoid LazyInitializationException
            List<EventPlaylistEntry> entries = playlistRepo.findByEventIdWithTrackEager(eventId);
            UUID currentPlayingId = currentlyPlaying.get(eventId);
            if (!entries.isEmpty()) {
                if (currentPlayingId != null) {
                    EventPlaylistEntry playingEntry = null;
                    List<EventPlaylistEntry> remaining = new ArrayList<>();
                    for (EventPlaylistEntry entry : entries) {
                        if (entry.getId().equals(currentPlayingId)) {
                            playingEntry = entry;
                        } else {
                            remaining.add(entry);
                        }
                    }

                    remaining.sort((a, b) -> {
                        int voteCompare = Integer.compare(b.getVoteCount(), a.getVoteCount());
                        if (voteCompare != 0) return voteCompare;
                        java.time.LocalDateTime aTime = a.getSuggestedAt() != null ? a.getSuggestedAt() : java.time.LocalDateTime.MIN;
                        java.time.LocalDateTime bTime = b.getSuggestedAt() != null ? b.getSuggestedAt() : java.time.LocalDateTime.MIN;
                        return aTime.compareTo(bTime);
                    });

                    entries = new ArrayList<>();
                    if (playingEntry != null) {
                        entries.add(playingEntry);
                    }
                    entries.addAll(remaining);
                } else {
                    entries = new ArrayList<>(entries);
                    entries.sort((a, b) -> {
                        int voteCompare = Integer.compare(b.getVoteCount(), a.getVoteCount());
                        if (voteCompare != 0) return voteCompare;
                        java.time.LocalDateTime aTime = a.getSuggestedAt() != null ? a.getSuggestedAt() : java.time.LocalDateTime.MIN;
                        java.time.LocalDateTime bTime = b.getSuggestedAt() != null ? b.getSuggestedAt() : java.time.LocalDateTime.MIN;
                        return aTime.compareTo(bTime);
                    });
                }
            }

            List<PlaylistEntryDto> playlist = new ArrayList<>();
            for (EventPlaylistEntry entry : entries) {
                playlist.add(toDto(entry));
            }

            Map<String, Object> message = new HashMap<>();
            message.put("type", "PLAYLIST_UPDATED");
            message.put("playlist", playlist);

            messagingTemplate.convertAndSend("/topic/event/" + eventId + "/playlist", message);
        } catch (Exception e) {
            log.error("Error broadcasting playlist update for event {}", eventId, e);
        }
    }

    @Override
    @Transactional
    public void skipTrack(UUID eventId, UUID userId, String clientTrackId) {
        Event event = eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found"));

        // Only owner or editor can skip tracks
        boolean isOwner = event.getOwner().getId().equals(userId);
        if (!isOwner) {
            Optional<EventInvite> inviteOpt = inviteRepo.findByEventIdAndUserId(eventId, userId);
            if (inviteOpt.isEmpty() || !"admin".equalsIgnoreCase(inviteOpt.get().getRole())) {
                throw new UnauthorizedException("Only the event owner or editors can skip tracks");
            }
        }

        UUID currentEntryId = currentlyPlaying.get(eventId);
        if (currentEntryId != null) {
            // Idempotency check: if client specified a trackId, make sure it matches the server's currently playing track's external ID!
            if (clientTrackId != null && !clientTrackId.trim().isEmpty()) {
                Optional<EventPlaylistEntry> entryOpt = playlistRepo.findById(currentEntryId);
                if (entryOpt.isPresent()) {
                    String serverTrackExternalId = entryOpt.get().getTrack().getExternalId();
                    if (!clientTrackId.equals(serverTrackExternalId)) {
                        log.info("Event {} skip request ignored: client requested to skip trackId '{}' but server is already playing '{}'",
                                eventId, clientTrackId, serverTrackExternalId);
                        return;
                    }
                }
            }

            log.info("Client user {} requested skip for event {} (current track: {})", userId, eventId, currentEntryId);
            advanceTrack(eventId, currentEntryId);
        } else {
            log.info("Client user {} requested skip for event {} but no track currently playing, advancing automatically", userId, eventId);
            playNextTrack(eventId);
        }
    }

    private PlaylistEntryDto toDto(EventPlaylistEntry entry) {
        List<VoteDto> votedList = new ArrayList<>();
        List<Vote> votes = voteRepo.findByPlaylistEntryId(entry.getId());
        if (votes != null) {
            for (Vote v : votes) {
                votedList.add(VoteDto.builder()
                        .userId(v.getUser().getId())
                        .displayName(v.getUser().getDisplayName())
                        .value(v.getValue())
                        .build());
            }
        }
        return PlaylistEntryDto.builder()
                .id(entry.getId())
                .title(entry.getTrack().getTitle())
                .artist(entry.getTrack().getArtist())
                .coverUrl(entry.getTrack().getCoverUrl())
                .durationMs(entry.getTrack().getDurationMs())
                .voteCount(entry.getVoteCount())
                .position(entry.getPosition())
                .status(entry.getStatus())
                .suggestedById(entry.getSuggestedBy() != null ? entry.getSuggestedBy().getId() : null)
                .suggestedByName(entry.getSuggestedBy() != null ? entry.getSuggestedBy().getDisplayName() : null)
                .externalId(entry.getTrack().getExternalId())
                .votedUsers(votedList)
                .build();
    }

    @Override
    public UUID getCurrentlyPlayingEntryId(UUID eventId) {
        return currentlyPlaying.get(eventId);
    }
}
