package com.musicroom.musicroom.dto.websocket;

import lombok.*;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class VoteMessage {
    private UUID entryId;   // id de la track dans l'event playlist
    private int value;      // +1 ou -1
}