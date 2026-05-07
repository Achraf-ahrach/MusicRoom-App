package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.UpdatePreferencesRequest;
import com.musicroom.musicroom.dto.UpdateProfileRequest;
import com.musicroom.musicroom.dto.UserProfileDto;
import com.musicroom.musicroom.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Tag(name = "User")
public class UserController {

    private final UserService userService;

    @Operation(summary = "Voir mon profil", description = "Retourne le profil complet de l'utilisateur connecté")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Profil retourné avec succès"),
        @ApiResponse(responseCode = "404", description = "Utilisateur non trouvé")
    })
    @GetMapping("/me")
    public ResponseEntity<UserProfileDto> getMyProfile(
            @AuthenticationPrincipal UserDetails userDetails) {

        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(userService.getMyProfile(userId));
    }

    @Operation(summary = "Voir le profil d'un autre utilisateur")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Profil retourné avec succès"),
        @ApiResponse(responseCode = "404", description = "Utilisateur non trouvé")
    })
    @GetMapping("/{id}")
    public ResponseEntity<UserProfileDto> getUserProfile(
            @AuthenticationPrincipal UserDetails userDetails,
            @Parameter(description = "ID de l'utilisateur cible")
            @PathVariable UUID id) {

        UUID requesterId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(userService.getUserProfile(requesterId, id));
    }

    @Operation(summary = "Modifier mon profil")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Profil modifié avec succès"),
        @ApiResponse(responseCode = "404", description = "Utilisateur non trouvé")
    })
    @PutMapping("/me")
    public ResponseEntity<UserProfileDto> updateMyProfile(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdateProfileRequest request) {

        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(userService.updateMyProfile(userId, request));
    }

    @Operation(summary = "Modifier mes préférences musicales")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Préférences modifiées avec succès"),
        @ApiResponse(responseCode = "404", description = "Utilisateur non trouvé")
    })
    @PutMapping("/me/preferences")
    public ResponseEntity<UserProfileDto> updatePreferences(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdatePreferencesRequest request) {

        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(userService.updatePreferences(userId, request));
    }
}