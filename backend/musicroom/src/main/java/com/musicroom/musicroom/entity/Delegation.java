package com.musicroom.musicroom.entity;

import com.musicroom.musicroom.enums.ResourceType;
import com.musicroom.musicroom.enums.PermissionLevel;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "delegations")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Delegation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;

    // @ManyToOne(fetch = FetchType.LAZY)
    // @JoinColumn(name = "device_id", nullable = false)
    // private Device device;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delegate_id", nullable = false)
    private User delegate;

    @Enumerated(EnumType.STRING)
    @Column(name = "resource_type", nullable = false)
    private ResourceType resourceType;

    // The actual ID of the playlist or event
    @Column(name = "resource_id", nullable = false)
    private UUID resourceId;



    // "full" | "play_pause" | "skip"
    @Enumerated(EnumType.STRING)
    @Column(name = "permission_level", nullable = false)
    private PermissionLevel permissionLevel;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}
