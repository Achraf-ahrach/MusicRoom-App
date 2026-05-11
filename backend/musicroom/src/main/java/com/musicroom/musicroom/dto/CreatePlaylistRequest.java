package com.musicroom.musicroom.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CreatePlaylistRequest {
    private String name;
    private String description;
    private String visibility;    // "public" | "private"
    private String licenseType;   // "open" | "invite_only"
}