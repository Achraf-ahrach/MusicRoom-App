package com.musicroom.musicroom.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdatePlaylistCollaboratorRoleRequest {
    private String permission; // "editor" | "viewer"
}
