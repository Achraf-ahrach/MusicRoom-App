package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.CreateDelegationRequestDto;
import com.musicroom.musicroom.dto.DelegationResponseDto;
import com.musicroom.musicroom.dto.UpdatePermissionDto;
import com.musicroom.musicroom.enums.ResourceType;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface DelegationService {

    DelegationResponseDto createDelegation(
            UUID ownerId,
            CreateDelegationRequestDto request,
            String ipAddress
    );

    List<DelegationResponseDto> getDelegations(
            ResourceType resourceType,
            UUID resourceId
    );

    DelegationResponseDto updatePermission(
            UUID delegationId,
            UUID ownerId,
            UpdatePermissionDto request,
            String ipAddress
    );

    void removeDelegation(
            UUID delegationId,
            UUID ownerId,
            String ipAddress
    );

    boolean hasPermission(
            UUID userId,
            ResourceType resourceType,
            UUID resourceId
    );

    List<DelegationResponseDto> getUserDelegations(UUID userId);

    boolean hasAccessToResource(UUID userId, UUID resourceId, ResourceType resourceType);

    Map<String, Object> getUserPermissionLevel(UUID userId, UUID resourceId, ResourceType resourceType);
}