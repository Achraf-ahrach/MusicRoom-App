package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.PlaylistTrack;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PlaylistTrackRepository extends JpaRepository<PlaylistTrack, UUID> {
    List<PlaylistTrack> findByPlaylistIdOrderByPosition(UUID playlistId);
    Optional<PlaylistTrack> findByPlaylistIdAndTrackId(UUID playlistId, UUID trackId);
    int countByPlaylistId(UUID playlistId);
    boolean existsByPlaylistIdAndTrackId(UUID playlistId, UUID trackId);
}