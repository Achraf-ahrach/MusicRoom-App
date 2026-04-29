package com.musicroom.musicroom.auth.dto.auth;

public record LoginRequestDTO (
    String email,
    String password
){}
