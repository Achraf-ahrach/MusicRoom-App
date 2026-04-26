package com.musicroom.musicroom.auth.dto.auth;


public record RegisterRequestDTO (
    String email,
    String password,
    String displayname
) {}
