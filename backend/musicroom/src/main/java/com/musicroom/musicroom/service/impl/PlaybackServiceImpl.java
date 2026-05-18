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
    private final SimpMessagingTemplate messagingTemplate;

    private final ScheduledExecutorService scheduler =
            Executors.newScheduledThreadPool(4);

    /** eventId -> currently scheduled auto-advance future */
    private final Map<UUID, ScheduledFuture<?>> scheduledAdvances = new ConcurrentHashMap<>();

    /** eventId -> ID of the track entry currently playing */
    private final Map<UUID, UUID> currentlyPlaying = new ConcurrentHashMap<>();

    /** Set of events that have been started */
    private final Set<UUID> activeEvents = ConcurrentHashMap.newKeySet();

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
        if (!event.getOwner().getId().equals(userId)) {
            throw new UnauthorizedException("Only the event owner can start playback");
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
        ScheduledFuture<?> future = scheduledAdvances.remove(eventId);
        if (future != null) {
            future.cancel(false);
        }
        log.info("Event {} playback stopped", eventId);
    }

    /**
     * Core logic: find the first track in the sorted queue, broadcast it, schedule auto-advance.
     */
    private void playNextTrack(UUID eventId) {
        try {
            List<EventPlaylistEntry> entries = playlistRepo.findByEventIdOrderBySuggestedAtAsc(eventId);

            // Sort: first track stays first (oldest), rest sorted by votes desc
            if (entries.size() > 1) {
                List<EventPlaylistEntry> rest = new ArrayList<>(entries.subList(1, entries.size()));
                rest.sort((a, b) -> {
                    int voteCompare = Integer.compare(b.getVoteCount(), a.getVoteCount());
                    if (voteCompare != 0) return voteCompare;
                    return a.getSuggestedAt().compareTo(b.getSuggestedAt());
                });
                entries = new ArrayList<>();
                entries.add(playlistRepo.findByEventIdOrderBySuggestedAtAsc(eventId).get(0));
                entries.addAll(rest);
            }

            if (entries.isEmpty()) {
                log.info("Event {} queue is empty, waiting for new tracks", eventId);
                currentlyPlaying.remove(eventId);

                // Broadcast QUEUE_EMPTY so clients know nothing is playing
                PlaybackMessage emptyMsg = new PlaybackMessage();
                emptyMsg.setCommand("QUEUE_EMPTY");
                messagingTemplate.convertAndSend("/topic/event/" + eventId + "/playback", emptyMsg);
                return;
            }

            EventPlaylistEntry firstEntry = entries.get(0);
            Track track = firstEntry.getTrack();
            currentlyPlaying.put(eventId, firstEntry.getId());

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

        } catch (Exception e) {
            log.error("Error playing next track for event {}", eventId, e);
        }
    }

    /**
     * Called when a track's duration has elapsed.
     * Removes the finished track and plays the next one.
     */
    @Transactional
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
            // Delete the finished track from the queue
            Optional<EventPlaylistEntry> entryOpt = playlistRepo.findById(finishedEntryId);
            if (entryOpt.isPresent()) {
                playlistRepo.delete(entryOpt.get());
                playlistRepo.flush();
                log.info("Event {} removed finished track {}", eventId, finishedEntryId);

                // Broadcast the updated playlist
                broadcastPlaylistUpdate(eventId);
            }

            // Play the next track
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
            List<EventPlaylistEntry> entries = playlistRepo.findByEventIdOrderBySuggestedAtAsc(eventId);
            if (entries.size() > 1) {
                entries.subList(1, entries.size()).sort((a, b) -> {
                    int voteCompare = Integer.compare(b.getVoteCount(), a.getVoteCount());
                    if (voteCompare != 0) return voteCompare;
                    java.time.LocalDateTime aTime = a.getSuggestedAt() != null ? a.getSuggestedAt() : java.time.LocalDateTime.MIN;
                    java.time.LocalDateTime bTime = b.getSuggestedAt() != null ? b.getSuggestedAt() : java.time.LocalDateTime.MIN;
                    return aTime.compareTo(bTime);
                });
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
}
