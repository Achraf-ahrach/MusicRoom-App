package com.musicroom.musicroom.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class SuggestTrackRequest {
    private String externalId;
    private String provider;   // "spotify" | "deezer" | "youtube"
    private String title;
    private String artist;
    private String album;
    private String coverUrl;
    private Integer durationMs;
}