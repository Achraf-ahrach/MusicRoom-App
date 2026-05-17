package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class VoteDto {
    private UUID userId;
    private String displayName;
    private int value;
}
