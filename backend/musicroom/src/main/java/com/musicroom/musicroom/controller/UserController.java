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
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Tag(name = "User")
public class UserController {

    private final UserService userService;

    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Profil retourné avec succès"),
        @ApiResponse(responseCode = "404", description = "Utilisateur non trouvé")
    })
    @GetMapping("/me")
    public ResponseEntity<UserProfileDto> getMyProfile(
            @Parameter(description = "ID de l'utilisateur connecté")
            @RequestParam UUID userId) {
        return ResponseEntity.ok(userService.getMyProfile(userId));
    }

    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Profil retourné avec succès"),
        @ApiResponse(responseCode = "404", description = "Utilisateur non trouvé")
    })
    @GetMapping("/{id}")
    public ResponseEntity<UserProfileDto> getUserProfile(
            @Parameter(description = "ID de l'utilisateur qui fait la requête")
            @RequestParam UUID requesterId,
            @Parameter(description = "ID de l'utilisateur cible")
            @PathVariable UUID id) {
        return ResponseEntity.ok(userService.getUserProfile(requesterId, id));
    }

    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Profil modifié avec succès"),
        @ApiResponse(responseCode = "404", description = "Utilisateur non trouvé")
    })
    @PutMapping("/me")
    public ResponseEntity<UserProfileDto> updateMyProfile(
            @Parameter(description = "ID de l'utilisateur connecté")
            @RequestParam UUID userId,
            @RequestBody UpdateProfileRequest request) {
        return ResponseEntity.ok(userService.updateMyProfile(userId, request));
    }

    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Préférences modifiées avec succès"),
        @ApiResponse(responseCode = "404", description = "Utilisateur non trouvé")
    })
    @PutMapping("/me/preferences")
    public ResponseEntity<UserProfileDto> updatePreferences(
            @Parameter(description = "ID de l'utilisateur connecté")
            @RequestParam UUID userId,
            @RequestBody UpdatePreferencesRequest request) {
        return ResponseEntity.ok(userService.updatePreferences(userId, request));
    }
}