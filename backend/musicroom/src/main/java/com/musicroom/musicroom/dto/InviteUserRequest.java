package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class InviteUserRequest {
    private UUID userId;
    private String role;   // "voter" | "admin"
}