package com.musicroom.musicroom.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "events")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;

    @Column(nullable = false)
    private String name;

    private String description;

    // "public" | "private"
    @Builder.Default
    @Column(nullable = false)
    private String visibility = "public";

    // "open" | "invite_only" | "location_time"
    @Builder.Default
    @Column(name = "license_type", nullable = false)
    private String licenseType = "open";

    private Double latitude;
    private Double longitude;

    @Column(name = "starts_at")
    private LocalDateTime startsAt;

    @Column(name = "cover_url", columnDefinition = "TEXT")
    private String coverUrl;

    @Column(name = "ends_at")
    private LocalDateTime endsAt;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Builder.Default
    @OneToMany(mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<EventInvite> invites = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("voteCount DESC, suggestedAt ASC")
    private List<EventPlaylistEntry> playlist = new ArrayList<>();

    @Builder.Default
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}
