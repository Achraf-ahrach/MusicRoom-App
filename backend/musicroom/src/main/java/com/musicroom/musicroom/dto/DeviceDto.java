package com.musicroom.musicroom.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record DeviceDto(
    UUID id,
    UUID userId,
    String deviceName,
    String platform,
    String appVersion,
    String pushToken,
    LocalDateTime lastSeen,
    LocalDateTime createdAt
) {}
