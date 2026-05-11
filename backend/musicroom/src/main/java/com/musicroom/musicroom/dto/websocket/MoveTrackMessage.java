package com.musicroom.musicroom.dto.websocket;

import lombok.*;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class MoveTrackMessage {

    // id de la track à déplacer
    private UUID trackId;

    // nouvelle position
    private Integer newPosition;

    // version actuelle du client
    private Integer version;
}