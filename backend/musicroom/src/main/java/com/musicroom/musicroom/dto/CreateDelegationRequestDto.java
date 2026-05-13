package com.musicroom.musicroom.dto;

import com.musicroom.musicroom.enums.PermissionLevel;
import com.musicroom.musicroom.enums.ResourceType;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
public class CreateDelegationRequestDto {
    private UUID delegateId;

    private ResourceType resourceType;

    private UUID resourceId;

    private PermissionLevel permissionLevel;

    private LocalDateTime expiresAt;
}