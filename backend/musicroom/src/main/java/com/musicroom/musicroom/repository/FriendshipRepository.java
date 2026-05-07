package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Friendship;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FriendshipRepository extends JpaRepository<Friendship, UUID> {

    List<Friendship> findByRequesterIdAndStatus(UUID requesterId, String status);
    List<Friendship> findByAddresseeIdAndStatus(UUID addresseeId, String status);
    Optional<Friendship> findByRequesterIdAndAddresseeId(UUID requesterId, UUID addresseeId);
    boolean existsByRequesterIdAndAddresseeId(UUID requesterId, UUID addresseeId);

    @Query("SELECT f FROM Friendship f WHERE " +
           "(f.requester.id = :userId OR f.addressee.id = :userId) " +
           "AND f.status = :status")
    List<Friendship> findAllByUserIdAndStatus(
            @Param("userId") UUID userId,
            @Param("status") String status);
}