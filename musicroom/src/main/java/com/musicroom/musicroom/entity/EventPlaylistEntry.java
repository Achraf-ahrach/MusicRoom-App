package com.musicroom.musicroom.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "event_playlist")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EventPlaylistEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "track_id", nullable = false)
    private Track track;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "suggested_by")
    private User suggestedBy;

    @Column(name = "vote_count", nullable = false)
    private int voteCount = 0;

    @Column(nullable = false)
    private int position = 0;

    // "queued" | "playing" | "played" | "skipped"
    @Column(nullable = false)
    private String status = "queued";

    @OneToMany(mappedBy = "playlistEntry", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Vote> votes = new ArrayList<>();

    @Column(name = "suggested_at", updatable = false)
    private LocalDateTime suggestedAt = LocalDateTime.now();
}
