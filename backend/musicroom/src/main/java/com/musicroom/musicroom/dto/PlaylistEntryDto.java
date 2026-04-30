package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class PlaylistEntryDto {
    private UUID id;
    private String title;
    private String artist;
    private String coverUrl;
    private Integer durationMs;
    private int voteCount;
    private int position;
    private String status;
    private UUID suggestedById;
    private String suggestedByName;
}