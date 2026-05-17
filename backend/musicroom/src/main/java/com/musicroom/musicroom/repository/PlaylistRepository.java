package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Playlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.UUID;

public interface PlaylistRepository extends JpaRepository<Playlist, UUID> {
    @Query("SELECT p FROM Playlist p JOIN FETCH p.owner WHERE p.owner.id = :ownerId")
    List<Playlist> findByOwnerId(@Param("ownerId") UUID ownerId);

    @Query("SELECT p FROM Playlist p JOIN FETCH p.owner WHERE p.visibility = :visibility")
    List<Playlist> findByVisibility(@Param("visibility") String visibility);

    @Query("SELECT p FROM Playlist p JOIN FETCH p.owner WHERE p.owner.id = :ownerId AND p.visibility = :visibility")
    List<Playlist> findByOwnerIdAndVisibility(@Param("ownerId") UUID ownerId, @Param("visibility") String visibility);

    @Query("SELECT p FROM Playlist p JOIN FETCH p.owner WHERE " +
           "p.owner.id = :userId OR " +
           "p.visibility = 'public' OR " +
           "EXISTS (SELECT pi FROM PlaylistInvite pi WHERE pi.playlist.id = p.id " +
           "AND pi.user.id = :userId)")
    List<Playlist> findAccessibleByUserId(@Param("userId") UUID userId);
}