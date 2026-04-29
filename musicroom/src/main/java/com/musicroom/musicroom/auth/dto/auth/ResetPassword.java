package com.musicroom.musicroom.auth.dto.auth;

public record ResetPassword(
    String email,
    String verificationCode,
    String newPassword
) {}
