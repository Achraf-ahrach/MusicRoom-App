package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface EventRepository extends JpaRepository<Event, UUID> {
    List<Event> findByActiveTrue();
    List<Event> findByVisibilityAndActiveTrue(String visibility);
    List<Event> findByOwnerIdAndActiveTrue(UUID ownerId);
}