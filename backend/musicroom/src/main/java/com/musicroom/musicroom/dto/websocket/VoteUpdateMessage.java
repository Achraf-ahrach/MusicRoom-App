package com.musicroom.musicroom.dto.websocket;

import com.musicroom.musicroom.dto.PlaylistEntryDto;
import lombok.*;
import java.util.List;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class VoteUpdateMessage {
    private VoteMessageType type;
    private UUID eventId;
    private UUID entryId;
    private UUID userId;
    private int newVoteCount;
    private String message;
    private List<PlaylistEntryDto> playlist;  // playlist complète reordonnée
}