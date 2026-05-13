package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.*;
import com.musicroom.musicroom.entity.Delegation;
import com.musicroom.musicroom.entity.User;
import com.musicroom.musicroom.enums.ResourceType;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.exception.UnauthorizedException;
import com.musicroom.musicroom.repository.DelegationRepository;
import com.musicroom.musicroom.repository.UserRepository;
import com.musicroom.musicroom.service.DelegationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.time.LocalDateTime;
import java.util.stream.Collectors;
import java.util.Map;
import java.util.HashMap;

@Service
@RequiredArgsConstructor
public class DelegationServiceImpl implements DelegationService {

    private final DelegationRepository delegationRepository;
    private final UserRepository userRepository;

    @Override
    public DelegationResponseDto createDelegation(
            UUID ownerId,
            CreateDelegationRequestDto request
    ) {


     

        User delegate = userRepository.findById(request.getDelegateId())
                .orElseThrow(() ->
                        new ResourceNotFoundException("Delegate user not found"));
        System.out.println("hello i wanna check if it's here and its will write soeint or no ");
        Delegation delegation = Delegation.builder()
                .owner(User.builder().id(ownerId).build())
                .delegate(delegate)
                .resourceType(request.getResourceType())
                .resourceId(request.getResourceId())
                .permissionLevel(request.getPermissionLevel())
                .expiresAt(request.getExpiresAt())
                .active(true)
                .build();

        delegationRepository.save(delegation);

        return mapToDto(delegation);
    }

    @Override
    public List<DelegationResponseDto> getDelegations(
            ResourceType resourceType,
            UUID resourceId
    ) {

        return delegationRepository
                .findByResourceTypeAndResourceId(resourceType, resourceId)
                .stream()
                .map(this::mapToDto)
                .toList();
    }

    @Override
    public DelegationResponseDto updatePermission(
            UUID delegationId,
            UUID ownerId,
            UpdatePermissionDto request
    ) {

        Delegation delegation = delegationRepository.findById(delegationId)
                .orElseThrow(() ->
                        new ResourceNotFoundException("Delegation not found"));

        if (!delegation.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException("Only owner can update permissions");
        }

        delegation.setPermissionLevel(request.getPermissionLevel());

        delegationRepository.save(delegation);

        return mapToDto(delegation);
    }

    @Override
    public void removeDelegation(
            UUID delegationId,
            UUID ownerId
    ) {

        Delegation delegation = delegationRepository.findById(delegationId)
                .orElseThrow(() ->
                        new ResourceNotFoundException("Delegation not found"));

        if (!delegation.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException("Only owner can remove delegation");
        }

        delegationRepository.delete(delegation);
    }

    @Override
    public boolean hasPermission(
            UUID userId,
            ResourceType resourceType,
            UUID resourceId
    ) {

        return delegationRepository
                .existsByDelegateIdAndResourceTypeAndResourceId(
                        userId,
                        resourceType,
                        resourceId
                );
    }

    @Override
    public List<DelegationResponseDto> getUserDelegations(UUID userId) {
        return delegationRepository
                .findByDelegateId(userId)
                .stream()
                .filter(this::isDelegationValid)
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Override
    public boolean hasAccessToResource(UUID userId, UUID resourceId, ResourceType resourceType) {
        List<Delegation> delegations = delegationRepository
                .findByDelegateIdAndResourceIdAndResourceType(userId, resourceId, resourceType);
        
        return delegations.stream().anyMatch(this::isDelegationValid);
    }

    @Override
    public Map<String, Object> getUserPermissionLevel(UUID userId, UUID resourceId, ResourceType resourceType) {
        List<Delegation> delegations = delegationRepository
                .findByDelegateIdAndResourceIdAndResourceType(userId, resourceId, resourceType);
        
        Map<String, Object> result = new HashMap<>();
        result.put("userId", userId);
        result.put("resourceId", resourceId);
        result.put("resourceType", resourceType);
        result.put("hasAccess", false);
        result.put("permissionLevel", null);
        result.put("isExpired", false);
        
        for (Delegation delegation : delegations) {
            if (isDelegationValid(delegation)) {
                result.put("hasAccess", true);
                result.put("permissionLevel", delegation.getPermissionLevel());
                result.put("isExpired", false);
                result.put("expiresAt", delegation.getExpiresAt());
                result.put("active", delegation.isActive());
                break;
            } else if (delegation.getExpiresAt() != null && delegation.getExpiresAt().isBefore(LocalDateTime.now())) {
                result.put("isExpired", true);
                result.put("expiresAt", delegation.getExpiresAt());
            }
        }
        
        return result;
    }

    private boolean isDelegationValid(Delegation delegation) {
        if (!delegation.isActive()) {
            return false;
        }
        if (delegation.getExpiresAt() != null && delegation.getExpiresAt().isBefore(LocalDateTime.now())) {
            return false;
        }
        return true;
    }

    private DelegationResponseDto mapToDto(Delegation delegation) {

        return DelegationResponseDto.builder()
                .id(delegation.getId())
                .ownerId(delegation.getOwner().getId())
                .delegateId(delegation.getDelegate().getId())
                .resourceType(delegation.getResourceType())
                .resourceId(delegation.getResourceId())
                .permissionLevel(delegation.getPermissionLevel())
                .active(delegation.isActive())
                .expiresAt(delegation.getExpiresAt())
                .createdAt(delegation.getCreatedAt())
                .build();
    }
}