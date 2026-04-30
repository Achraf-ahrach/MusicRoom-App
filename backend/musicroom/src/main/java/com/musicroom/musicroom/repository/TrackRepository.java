package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Track;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TrackRepository extends JpaRepository<Track, UUID> {
    Optional<Track> findByExternalIdAndProvider(String externalId, String provider);
    List<Track> findByProvider(String provider);
    List<Track> findByTitleContainingIgnoreCase(String title);
    List<Track> findByArtistContainingIgnoreCase(String artist);
}