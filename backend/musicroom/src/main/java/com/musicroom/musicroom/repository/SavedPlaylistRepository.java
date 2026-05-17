package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.SavedPlaylist;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SavedPlaylistRepository extends JpaRepository<SavedPlaylist, UUID> {
    Optional<SavedPlaylist> findByUserIdAndPlaylistId(UUID userId, UUID playlistId);
    boolean existsByUserIdAndPlaylistId(UUID userId, UUID playlistId);
    List<SavedPlaylist> findByUserId(UUID userId);
}
