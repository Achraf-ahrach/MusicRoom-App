package com.musicroom.musicroom.auth.dto.auth;

import java.util.UUID;


public record RegisterResponseDTO(
    UUID id,
    String email,
    String displayname,
    String avatarUrl,
    String emailVerified
) {}