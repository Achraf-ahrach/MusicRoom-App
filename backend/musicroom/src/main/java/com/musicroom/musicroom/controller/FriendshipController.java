package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.FriendRequestDto;
import com.musicroom.musicroom.dto.FriendshipDto;
import com.musicroom.musicroom.dto.UserSearchDto;
import com.musicroom.musicroom.service.FriendshipService;
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
@RequestMapping("/api/friendships")
@RequiredArgsConstructor
@Tag(name = "Friendship", description = "Gestion des amis")
public class FriendshipController {

    private final FriendshipService friendshipService;

    @Operation(summary = "Envoyer une demande d'amitié")
    @PostMapping("/request")
    public ResponseEntity<FriendshipDto> sendRequest(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody FriendRequestDto request) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.status(201)
                .body(friendshipService.sendRequest(userId, request));
    }

    @Operation(summary = "Liste mes amis acceptés")
    @GetMapping
    public ResponseEntity<List<FriendshipDto>> getMyFriends(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(friendshipService.getMyFriends(userId));
    }

    @Operation(summary = "Demandes d'amitié reçues en attente")
    @GetMapping("/pending")
    public ResponseEntity<List<FriendshipDto>> getPendingRequests(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(friendshipService.getPendingRequests(userId));
    }

    @Operation(summary = "Accepter une demande d'amitié")
    @PutMapping("/{id}/accept")
    public ResponseEntity<FriendshipDto> acceptRequest(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(friendshipService.acceptRequest(userId, id));
    }

    @Operation(summary = "Refuser une demande d'amitié")
    @PutMapping("/{id}/decline")
    public ResponseEntity<FriendshipDto> declineRequest(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(friendshipService.declineRequest(userId, id));
    }

    @Operation(summary = "Supprimer un ami")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFriend(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        friendshipService.deleteFriend(userId, id);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Rechercher un utilisateur par nom")
    @GetMapping("/search")
    public ResponseEntity<List<UserSearchDto>> searchUsers(
            @RequestParam String name) {
        return ResponseEntity.ok(friendshipService.searchUsers(name));
    }
}