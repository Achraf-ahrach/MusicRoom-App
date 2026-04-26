package com.musicroom.musicroom.auth.dto.auth;

public record TokenRefreshResponseDTO(
    String accessToken,
    String refreshToken,
    String tokenType,
    long expiresIn
) {}
