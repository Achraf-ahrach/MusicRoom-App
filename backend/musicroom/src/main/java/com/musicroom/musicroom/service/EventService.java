package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.*;
import java.util.List;
import java.util.UUID;

public interface EventService {
    EventDto createEvent(UUID ownerId, CreateEventRequest request);
    List<EventDto> getAllPublicEvents();
    EventDto getEventById(UUID eventId);
    EventDto updateEvent(UUID ownerId, UUID eventId, CreateEventRequest request);
    void deleteEvent(UUID ownerId, UUID eventId);
    void inviteUser(UUID ownerId, UUID eventId, InviteUserRequest request);
    List<PlaylistEntryDto> getPlaylist(UUID eventId);
    PlaylistEntryDto suggestTrack(UUID userId, UUID eventId, SuggestTrackRequest request);
    PlaylistEntryDto vote(UUID userId, UUID eventId, UUID entryId, VoteRequest request);
}