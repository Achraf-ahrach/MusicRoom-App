package com.musicroom.musicroom.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class PlaylistDto {
    private UUID id;
    private String name;
    private String description;
    private String visibility;
    private String licenseType;
    private Integer version;
    private UUID ownerId;
    private String ownerName;
    private int trackCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String coverUrl;
}