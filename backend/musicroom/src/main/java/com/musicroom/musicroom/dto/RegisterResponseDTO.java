package com.musicroom.musicroom.dto;

import java.util.UUID;


public record RegisterResponseDTO(
    UUID id,
    String email,
    String displayname,
    String avatarUrl,
    String emailVerified
) {}