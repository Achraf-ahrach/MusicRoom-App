package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class PlaylistTrackDto {
    private UUID id;
    private String externalId;
    private String title;
    private String artist;
    private String album;
    private String coverUrl;
    private Integer durationMs;
    private Integer position;
    private UUID addedBy;
}