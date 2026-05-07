package com.musicroom.musicroom.dto;

public record VerifyEmailDTO(
    String email,
    String verificationCode
) {}
