package com.musicroom.musicroom.dto;

public record ResetPassword(
    String email,
    String verificationCode,
    String newPassword
) {}
