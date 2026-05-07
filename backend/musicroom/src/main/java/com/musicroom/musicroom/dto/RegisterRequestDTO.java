package com.musicroom.musicroom.dto;


public record RegisterRequestDTO (
    String email,
    String password,
    String displayname
) {}
