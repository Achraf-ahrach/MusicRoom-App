package com.musicroom.musicroom.dto.websocket;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class AddTrackMessage {

    // id de la track à ajouter
    private String externalId;
    private String provider;
    private String title;
    private String artist;
    private String album;
    private String coverUrl;
    private Integer durationMs;

    // version actuelle du client pour détecter les conflits
    private Integer version;
}