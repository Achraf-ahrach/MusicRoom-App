package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.*;
import com.musicroom.musicroom.entity.*;
import com.musicroom.musicroom.exception.ConflictException;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.exception.UnauthorizedException;
import com.musicroom.musicroom.repository.*;
import com.musicroom.musicroom.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EventServiceImpl implements EventService {

    private final EventRepository eventRepo;
    private final UserRepository userRepo;
    private final EventInviteRepository inviteRepo;
    private final EventPlaylistRepository playlistRepo;
    private final VoteRepository voteRepo;
    private final TrackRepository trackRepo;

    @Override
    @Transactional
    public EventDto createEvent(UUID ownerId, CreateEventRequest request) {
        User owner = userRepo.findById(ownerId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Event event = Event.builder()
                .owner(owner)
                .name(request.getName())
                .description(request.getDescription())
                .visibility(request.getVisibility() != null ? request.getVisibility() : "public")
                .licenseType(request.getLicenseType() != null ? request.getLicenseType() : "open")
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .startsAt(request.getStartsAt())
                .endsAt(request.getEndsAt())
                .active(true)
                .build();

        eventRepo.save(event);
        return toDto(event);
    }

    @Override
    public List<EventDto> getAllPublicEvents() {
        return eventRepo.findByVisibilityAndActiveTrue("public")
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    public EventDto getEventById(UUID eventId) {
        Event event = eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found"));
        return toDto(event);
    }

    @Override
    @Transactional
    public EventDto updateEvent(UUID ownerId, UUID eventId, CreateEventRequest request) {
        Event event = eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found"));

        if (!event.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException("Not authorized to update this event");
        }

        if (request.getName() != null) event.setName(request.getName());
        if (request.getDescription() != null) event.setDescription(request.getDescription());
        if (request.getVisibility() != null) event.setVisibility(request.getVisibility());
        if (request.getLicenseType() != null) event.setLicenseType(request.getLicenseType());
        if (request.getStartsAt() != null) event.setStartsAt(request.getStartsAt());
        if (request.getEndsAt() != null) event.setEndsAt(request.getEndsAt());

        eventRepo.save(event);
        return toDto(event);
    }

    @Override
    @Transactional
    public void deleteEvent(UUID ownerId, UUID eventId) {
        Event event = eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found"));

        if (!event.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException("Not authorized to delete this event");
        }

        event.setActive(false);
        eventRepo.save(event);
    }

    @Override
    @Transactional
    public void inviteUser(UUID ownerId, UUID eventId, InviteUserRequest request) {
        Event event = eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found"));

        if (!event.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException("Not authorized to invite users to this event");
        }

        if (inviteRepo.existsByEventIdAndUserId(eventId, request.getUserId())) {
            throw new ConflictException("User already invited to this event");
        }

        User user = userRepo.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        EventInvite invite = EventInvite.builder()
                .event(event)
                .user(user)
                .role(request.getRole() != null ? request.getRole() : "voter")
                .build();

        inviteRepo.save(invite);
    }

    @Override
    public List<PlaylistEntryDto> getPlaylist(UUID eventId) {
        eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found"));

        return playlistRepo.findByEventIdOrderByVoteCountDesc(eventId)
                .stream()
                .map(this::toPlaylistEntryDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public PlaylistEntryDto suggestTrack(UUID userId, UUID eventId, SuggestTrackRequest request) {
        Event event = eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found"));

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Track track = trackRepo
                .findByExternalIdAndProvider(request.getExternalId(), request.getProvider())
                .orElseGet(() -> trackRepo.save(Track.builder()
                        .externalId(request.getExternalId())
                        .provider(request.getProvider())
                        .title(request.getTitle())
                        .artist(request.getArtist())
                        .album(request.getAlbum())
                        .coverUrl(request.getCoverUrl())
                        .durationMs(request.getDurationMs())
                        .build()));

        if (playlistRepo.existsByEventIdAndTrackId(eventId, track.getId())) {
            throw new ConflictException("Track already in playlist");
        }

        EventPlaylistEntry entry = EventPlaylistEntry.builder()
                .event(event)
                .track(track)
                .suggestedBy(user)
                .voteCount(0)
                .position(0)
                .status("queued")
                .build();

        playlistRepo.save(entry);
        return toPlaylistEntryDto(entry);
    }

    @Override
    @Transactional
    public PlaylistEntryDto vote(UUID userId, UUID eventId, UUID entryId, VoteRequest request) {
        EventPlaylistEntry entry = playlistRepo.findById(entryId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist entry not found"));

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (voteRepo.existsByPlaylistEntryIdAndUserId(entryId, userId)) {
            throw new ConflictException("User has already voted for this track");
        }

        Vote vote = Vote.builder()
                .playlistEntry(entry)
                .user(user)
                .value(request.getValue())
                .build();

        voteRepo.save(vote);

        entry.setVoteCount(entry.getVoteCount() + request.getValue());
        playlistRepo.save(entry);

        return toPlaylistEntryDto(entry);
    }

    private EventDto toDto(Event event) {
        return EventDto.builder()
                .id(event.getId())
                .name(event.getName())
                .description(event.getDescription())
                .visibility(event.getVisibility())
                .licenseType(event.getLicenseType())
                .latitude(event.getLatitude())
                .longitude(event.getLongitude())
                .startsAt(event.getStartsAt())
                .endsAt(event.getEndsAt())
                .active(event.isActive())
                .ownerId(event.getOwner().getId())
                .ownerName(event.getOwner().getDisplayName())
                .trackCount(event.getPlaylist().size())
                .createdAt(event.getCreatedAt())
                .build();
    }

    private PlaylistEntryDto toPlaylistEntryDto(EventPlaylistEntry entry) {
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
                .build();
    }
}