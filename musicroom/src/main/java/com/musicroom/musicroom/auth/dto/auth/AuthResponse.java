package com.musicroom.musicroom.auth.dto.auth;

public record AuthResponse (
    String accessToken,
    String refreshToken,
    String tokenType,
    long expiresIn,
    RegisterResponseDTO userInfo
) {}
