package com.musicroom.musicroom.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CreateEventRequest {
    private String name;
    private String description;
    private String visibility;       // "public" | "private"
    private String licenseType;      // "open" | "invite_only" | "location_time"
    private Double latitude;
    private Double longitude;
    private LocalDateTime startsAt;
    private LocalDateTime endsAt;
}