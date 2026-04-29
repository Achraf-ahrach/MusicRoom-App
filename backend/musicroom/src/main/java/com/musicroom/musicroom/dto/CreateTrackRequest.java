package com.musicroom.musicroom.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CreateTrackRequest {
    private String externalId;
    private String provider;
    private String title;
    private String artist;
    private String album;
    private String coverUrl;
    private Integer durationMs;
}