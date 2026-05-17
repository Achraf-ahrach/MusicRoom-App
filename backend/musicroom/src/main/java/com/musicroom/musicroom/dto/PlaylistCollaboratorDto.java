package com.musicroom.musicroom.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlaylistCollaboratorDto {
    private UUID userId;
    private String displayName;
    private String avatarUrl;
    private String permission; // "editor" | "viewer"
}
