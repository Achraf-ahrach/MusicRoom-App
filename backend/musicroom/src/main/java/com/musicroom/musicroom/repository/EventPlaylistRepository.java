package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.EventPlaylistEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.UUID;

public interface EventPlaylistRepository extends JpaRepository<EventPlaylistEntry, UUID> {
    List<EventPlaylistEntry> findByEventIdOrderByVoteCountDesc(UUID eventId);
    List<EventPlaylistEntry> findByEventIdOrderBySuggestedAtAsc(UUID eventId);
    boolean existsByEventIdAndTrackId(UUID eventId, UUID trackId);
    long countByEventId(UUID eventId);

    /**
     * Eagerly fetches Track and SuggestedBy to avoid LazyInitializationException
     * when called from outside a Spring-managed transaction (e.g. scheduled threads).
     */
    @Query("SELECT e FROM EventPlaylistEntry e " +
           "LEFT JOIN FETCH e.track " +
           "LEFT JOIN FETCH e.suggestedBy " +
           "WHERE e.event.id = :eventId " +
           "ORDER BY e.suggestedAt ASC")
    List<EventPlaylistEntry> findByEventIdWithTrackEager(@Param("eventId") UUID eventId);
}