package com.musicroom.musicroom.auth.dto.auth;

public record VerifyEmailDTO(
    String email,
    String verificationCode
) {}
