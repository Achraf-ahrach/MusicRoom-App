package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Vote;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface VoteRepository extends JpaRepository<Vote, UUID> {
    Optional<Vote> findByPlaylistEntryIdAndUserId(UUID entryId, UUID userId);
    boolean existsByPlaylistEntryIdAndUserId(UUID entryId, UUID userId);
}