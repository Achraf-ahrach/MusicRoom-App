package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.PlaylistInvite;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface PlaylistInviteRepository extends JpaRepository<PlaylistInvite, UUID> {
    boolean existsByPlaylistIdAndUserId(UUID playlistId, UUID userId);
    Optional<PlaylistInvite> findByPlaylistIdAndUserId(UUID playlistId, UUID userId);
}