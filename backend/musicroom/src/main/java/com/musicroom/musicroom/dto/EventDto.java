package com.musicroom.musicroom.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class EventDto {
    private UUID id;
    private String name;
    private String description;
    private String visibility;
    private String licenseType;
    private Double latitude;
    private Double longitude;
    private LocalDateTime startsAt;
    private LocalDateTime endsAt;
    private boolean active;
    private boolean isPlaying;
    private UUID ownerId;
    private String ownerName;
    private int trackCount;
    private int participantCount;
    private LocalDateTime createdAt;
    private String coverUrl;
    private String firstTrackCoverUrl;
}