package com.musicroom.musicroom.dto.websocket;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class PlaybackMessage {
    private String trackId;
    private String title;
    private String artist;
    private String coverUrl;
    private String audioUrl;
    private String suggestedByName;
    private String command; // "PLAY", "PAUSE", "SEEK", "STOP"
    private Long positionMs;
}
