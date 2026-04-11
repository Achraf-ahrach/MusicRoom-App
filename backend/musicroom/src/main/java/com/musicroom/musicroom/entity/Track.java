package com.musicroom.musicroom.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "tracks",
    uniqueConstraints = @UniqueConstraint(columnNames = {"external_id", "provider"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Track {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "external_id", nullable = false)
    private String externalId;

    @Column(nullable = false)
    private String provider; // "spotify" | "deezer" | "youtube"

    @Column(nullable = false)
    private String title;

    private String artist;
    private String album;

    @Column(name = "cover_url")
    private String coverUrl;

    @Column(name = "duration_ms")
    private Integer durationMs;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}
