package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.*;
import com.musicroom.musicroom.service.EventService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
@Tag(name = "Event", description = "Gestion des événements musicaux")
public class EventController {

    private final EventService eventService;

    @PostMapping
    public ResponseEntity<EventDto> createEvent(
            @RequestParam UUID userId,
            @RequestBody CreateEventRequest request) {
        return ResponseEntity.status(201).body(eventService.createEvent(userId, request));
    }

    @GetMapping
    public ResponseEntity<List<EventDto>> getAllPublicEvents() {
        return ResponseEntity.ok(eventService.getAllPublicEvents());
    }

    @GetMapping("/{id}")
    public ResponseEntity<EventDto> getEventById(@PathVariable UUID id) {
        return ResponseEntity.ok(eventService.getEventById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EventDto> updateEvent(
            @RequestParam UUID userId,
            @PathVariable UUID id,
            @RequestBody CreateEventRequest request) {
        return ResponseEntity.ok(eventService.updateEvent(userId, id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEvent(
            @RequestParam UUID userId,
            @PathVariable UUID id) {
        eventService.deleteEvent(userId, id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/invite")
    public ResponseEntity<Void> inviteUser(
            @RequestParam UUID userId,
            @PathVariable UUID id,
            @RequestBody InviteUserRequest request) {
        eventService.inviteUser(userId, id, request);
        return ResponseEntity.status(201).build();
    }

    @GetMapping("/{id}/playlist")
    public ResponseEntity<List<PlaylistEntryDto>> getPlaylist(@PathVariable UUID id) {
        return ResponseEntity.ok(eventService.getPlaylist(id));
    }

    @PostMapping("/{id}/playlist")
    public ResponseEntity<PlaylistEntryDto> suggestTrack(
            @RequestParam UUID userId,
            @PathVariable UUID id,
            @RequestBody SuggestTrackRequest request) {
        return ResponseEntity.status(201).body(eventService.suggestTrack(userId, id, request));
    }

    @PostMapping("/{id}/playlist/{entryId}/vote")
    public ResponseEntity<PlaylistEntryDto> vote(
            @RequestParam UUID userId,
            @PathVariable UUID id,
            @PathVariable UUID entryId,
            @RequestBody VoteRequest request) {
        return ResponseEntity.ok(eventService.vote(userId, id, entryId, request));
    }
}