package com.musicroom.musicroom.dto;

public record AuthResponse (
    String accessToken,
    String refreshToken,
    String tokenType,
    long expiresIn,
    RegisterResponseDTO userInfo
) {}
