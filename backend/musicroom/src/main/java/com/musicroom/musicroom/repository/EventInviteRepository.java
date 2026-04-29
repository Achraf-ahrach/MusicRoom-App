package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.EventInvite;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface EventInviteRepository extends JpaRepository<EventInvite, UUID> {
    boolean existsByEventIdAndUserId(UUID eventId, UUID userId);
    Optional<EventInvite> findByEventIdAndUserId(UUID eventId, UUID userId);
}