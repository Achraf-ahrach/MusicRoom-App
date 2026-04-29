package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class TrackDto {
    private UUID id;
    private String externalId;
    private String provider;
    private String title;
    private String artist;
    private String album;
    private String coverUrl;
    private Integer durationMs;
}