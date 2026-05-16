package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Playlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface PlaylistRepository extends JpaRepository<Playlist, UUID> {
    List<Playlist> findByOwnerId(UUID ownerId);
    @EntityGraph(attributePaths = "owner")
    List<Playlist> findByVisibility(String visibility);
    @Query("SELECT p FROM Playlist p JOIN FETCH p.owner WHERE p.owner.id = :userId OR " +
           "EXISTS (SELECT pi FROM PlaylistInvite pi WHERE pi.playlist.id = p.id " +
           "AND pi.user.id = :userId)")
    List<Playlist> findAccessibleByUserId(@Param("userId") UUID userId);
}