package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Friendship;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface FriendshipRepository extends JpaRepository<Friendship, UUID> {
    List<Friendship> findByRequesterIdAndStatus(UUID requesterId, String status);
    List<Friendship> findByAddresseeIdAndStatus(UUID addresseeId, String status);
}