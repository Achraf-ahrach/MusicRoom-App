package com.musicroom.musicroom.dto;

public record TokenRefreshResponseDTO(
    String accessToken,
    String refreshToken,
    String tokenType,
    long expiresIn
) {}
