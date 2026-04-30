package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.EventPlaylistEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface EventPlaylistRepository extends JpaRepository<EventPlaylistEntry, UUID> {
    List<EventPlaylistEntry> findByEventIdOrderByVoteCountDesc(UUID eventId);
    boolean existsByEventIdAndTrackId(UUID eventId, UUID trackId);
}