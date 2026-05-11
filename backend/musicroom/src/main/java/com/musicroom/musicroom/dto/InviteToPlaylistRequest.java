package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class InviteToPlaylistRequest {
    private UUID userId;
    private String permission;  // "viewer" | "editor"
}