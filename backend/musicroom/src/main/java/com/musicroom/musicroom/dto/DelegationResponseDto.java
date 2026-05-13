package com.musicroom.musicroom.dto;

import com.musicroom.musicroom.enums.PermissionLevel;
import com.musicroom.musicroom.enums.ResourceType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class DelegationResponseDto {

    private UUID id;
    private UUID ownerId;
    private UUID delegateId;
    private ResourceType resourceType;
    private UUID resourceId;
    private PermissionLevel permissionLevel;
    private boolean active;
    private LocalDateTime expiresAt;
    private LocalDateTime createdAt;
}