package com.musicroom.musicroom.auth.dto.auth;

import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class RegisterResponseDTO {
    private UUID id;
    private String email;
    private String displayname;
    private String avatarUrl;
    private String emailVerified;
}
