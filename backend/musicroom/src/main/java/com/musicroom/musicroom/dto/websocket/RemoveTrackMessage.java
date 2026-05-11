package com.musicroom.musicroom.dto.websocket;

import lombok.*;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class RemoveTrackMessage {

    // id de la playlist track à supprimer
    private UUID trackId;

    // version actuelle du client
    private Integer version;
}