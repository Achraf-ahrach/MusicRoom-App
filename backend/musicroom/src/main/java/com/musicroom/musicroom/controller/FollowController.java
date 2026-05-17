package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.UserSearchDto;
import com.musicroom.musicroom.service.FollowService;
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
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Tag(name = "Follow", description = "Gestion des abonnements")
public class FollowController {

    private final FollowService followService;

    @Operation(summary = "S'abonner à un utilisateur")
    @PostMapping("/{id}/follow")
    public ResponseEntity<Void> followUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id) {
        UUID followerId = UUID.fromString(userDetails.getUsername());
        followService.followUser(followerId, id);
        return ResponseEntity.ok().build();
    }

    @Operation(summary = "Se désabonner d'un utilisateur")
    @DeleteMapping("/{id}/follow")
    public ResponseEntity<Void> unfollowUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id) {
        UUID followerId = UUID.fromString(userDetails.getUsername());
        followService.unfollowUser(followerId, id);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Vérifier si on suit un utilisateur")
    @GetMapping("/{id}/is-following")
    public ResponseEntity<Boolean> isFollowing(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID id) {
        UUID followerId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(followService.isFollowing(followerId, id));
    }

    @Operation(summary = "Obtenir les abonnés d'un utilisateur")
    @GetMapping("/{id}/followers")
    public ResponseEntity<List<UserSearchDto>> getFollowers(@PathVariable UUID id) {
        return ResponseEntity.ok(followService.getFollowers(id));
    }

    @Operation(summary = "Obtenir les abonnements d'un utilisateur")
    @GetMapping("/{id}/following")
    public ResponseEntity<List<UserSearchDto>> getFollowing(@PathVariable UUID id) {
        return ResponseEntity.ok(followService.getFollowing(id));
    }
}
