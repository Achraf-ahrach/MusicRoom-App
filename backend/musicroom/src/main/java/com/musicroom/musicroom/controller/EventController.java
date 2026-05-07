package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.*;
import com.musicroom.musicroom.service.EventService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
@Tag(name = "Event", description = "Gestion des événements musicaux")
public class EventController {

    private final EventService eventService;

    @Operation(summary = "Créer un événement")
    @PostMapping
    public ResponseEntity<EventDto> createEvent(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody CreateEventRequest request) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.status(201).body(eventService.createEvent(userId, request));
    }

    @Operation(summary = "Liste tous les événements publics")
    @GetMapping
    public ResponseEntity<List<EventDto>> getAllPublicEvents() {
        return ResponseEntity.ok(eventService.getAllPublicEvents());
    }

    @Operation(summary = "Détail d'un événement")
    @GetMapping("/{id}")
    public ResponseEntity<EventDto> getEventById(@PathVariable UUID id) {
        return ResponseEntity.ok(eventService.getEventById(id));
    }

    @Operation(summary = "Modifier un événement")
    @PutMapping("/{id}")
    public ResponseEntity<EventDto> updateEvent(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id,
            @RequestBody CreateEventRequest request) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(eventService.updateEvent(userId, id, request));
    }

    @Operation(summary = "Supprimer un événement")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEvent(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        eventService.deleteEvent(userId, id);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Inviter un utilisateur à l'événement")
    @PostMapping("/{id}/invite")
    public ResponseEntity<Void> inviteUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id,
            @RequestBody InviteUserRequest request) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        eventService.inviteUser(userId, id, request);
        return ResponseEntity.status(201).build();
    }

    @Operation(summary = "Voir la playlist de l'événement")
    @GetMapping("/{id}/playlist")
    public ResponseEntity<List<PlaylistEntryDto>> getPlaylist(
            @PathVariable UUID id) {
        return ResponseEntity.ok(eventService.getPlaylist(id));
    }

    @Operation(summary = "Suggérer une track")
    @PostMapping("/{id}/playlist")
    public ResponseEntity<PlaylistEntryDto> suggestTrack(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id,
            @RequestBody SuggestTrackRequest request) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.status(201).body(eventService.suggestTrack(userId, id, request));
    }

    @Operation(summary = "Voter pour une track")
    @PostMapping("/{id}/playlist/{entryId}/vote")
    public ResponseEntity<PlaylistEntryDto> vote(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id,
            @PathVariable UUID entryId,
            @RequestBody VoteRequest request) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(eventService.vote(userId, id, entryId, request));
    }
}