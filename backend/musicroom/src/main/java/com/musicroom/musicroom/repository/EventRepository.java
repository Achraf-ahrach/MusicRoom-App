package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.UUID;

public interface EventRepository extends JpaRepository<Event, UUID> {
    List<Event> findByActiveTrue();
    List<Event> findByVisibilityAndActiveTrue(String visibility);
    List<Event> findByOwnerIdAndActiveTrue(UUID ownerId);

    @Query("SELECT DISTINCT e FROM Event e " +
           "LEFT JOIN e.invites i " +
           "LEFT JOIN FETCH e.owner " +
           "WHERE e.active = true AND " +
           "(e.visibility = 'public' OR e.owner.id = :userId OR i.user.id = :userId)")
    List<Event> findActivePublicOwnedOrInvitedEvents(@Param("userId") UUID userId);
}