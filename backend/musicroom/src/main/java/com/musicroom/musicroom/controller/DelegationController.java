package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.*;
import com.musicroom.musicroom.enums.ResourceType;
import com.musicroom.musicroom.security.JwtTokenProvider;
import com.musicroom.musicroom.service.DelegationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/delegations")
@RequiredArgsConstructor
public class DelegationController {

    private final DelegationService delegationService;
    private final JwtTokenProvider jwtTokenProvider;

    private UUID extractUserIdFromToken(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            throw new IllegalArgumentException("Missing or invalid Authorization header. Expected: Bearer {token}");
        }
        
        String token = authorizationHeader.substring(7);
        
        if (!jwtTokenProvider.validateToken(token)) {
            throw new IllegalArgumentException("Invalid or expired token");
        }
        
        return UUID.fromString(jwtTokenProvider.getUserIdFromToken(token));
    }

    // POST - Create delegation 
    @PostMapping("/add-delegation")
    public ResponseEntity<DelegationResponseDto> createDelegation(
            @RequestHeader(value = "Authorization", required = true) String authorizationHeader,
            @RequestBody CreateDelegationRequestDto request
    ) {
        UUID ownerId = extractUserIdFromToken(authorizationHeader);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(delegationService.createDelegation(ownerId, request));
    }

    // GET - Get all delegations for a resource
    @GetMapping("/resource/{resourceId}")
    public ResponseEntity<List<DelegationResponseDto>> getDelegations(
            @PathVariable UUID resourceId,
            @RequestParam(name = "type") String resourceType
    ) {
        return ResponseEntity.ok(delegationService.getDelegations(
                ResourceType.valueOf(resourceType), 
                resourceId
        ));
    }

    // GET - Get all delegations received by a user
    @GetMapping("/my-delegations")
    public ResponseEntity<List<DelegationResponseDto>> getUserDelegations(
            @RequestHeader(value = "Authorization", required = true) String authorizationHeader
    ) {
        UUID userId = extractUserIdFromToken(authorizationHeader);
        return ResponseEntity.ok(delegationService.getUserDelegations(userId));
    }

    // POST - Check if user has access 
    @PostMapping("/check-access")
    public ResponseEntity<Map<String, Object>> checkAccess(
            @RequestHeader(value = "Authorization", required = true) String authorizationHeader,
            @RequestBody CheckAccessRequestDto request
    ) {
        UUID userId = extractUserIdFromToken(authorizationHeader);
        boolean hasAccess = delegationService.hasAccessToResource(
                userId, 
                request.getResourceId(), 
                request.getResourceType()
        );
        return ResponseEntity.ok(Map.of(
            "userId", userId,
            "resourceId", request.getResourceId(),
            "resourceType", request.getResourceType(),
            "hasAccess", hasAccess
        ));
    }

    // GET - Get user's permission level for a resource
    @GetMapping("/permission-level")
    public ResponseEntity<Map<String, Object>> getPermissionLevel(
            @RequestHeader(value = "Authorization", required = true) String authorizationHeader,
            @RequestParam(name = "resourceId") UUID resourceId,
            @RequestParam(name = "type") String resourceType
    ) {
        UUID userId = extractUserIdFromToken(authorizationHeader);
        var permissionInfo = delegationService.getUserPermissionLevel(userId, resourceId, ResourceType.valueOf(resourceType));
        return ResponseEntity.ok(permissionInfo);
    }

    // PUT - Update permission 
    @PutMapping("/{delegationId}")
    public ResponseEntity<DelegationResponseDto> updatePermission(
            @RequestHeader(value = "Authorization", required = true) String authorizationHeader,
            @PathVariable UUID delegationId,
            @RequestBody UpdatePermissionDto request
    ) {
        UUID ownerId = extractUserIdFromToken(authorizationHeader);
        return ResponseEntity.ok(delegationService.updatePermission(
                delegationId, 
                ownerId, 
                request
        ));
    }

    // DELETE - Remove delegation
    @DeleteMapping("/{delegationId}")
    public ResponseEntity<Void> removeDelegation(
            @RequestHeader(value = "Authorization", required = true) String authorizationHeader,
            @PathVariable UUID delegationId
    ) {
        UUID ownerId = extractUserIdFromToken(authorizationHeader);
        delegationService.removeDelegation(delegationId, ownerId);
        return ResponseEntity.noContent().build();
    }
}