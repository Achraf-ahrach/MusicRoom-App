package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.UserFollow;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserFollowRepository extends JpaRepository<UserFollow, UUID> {
    Optional<UserFollow> findByFollowerIdAndFollowingId(UUID followerId, UUID followingId);
    boolean existsByFollowerIdAndFollowingId(UUID followerId, UUID followingId);
    List<UserFollow> findByFollowerId(UUID followerId);
    List<UserFollow> findByFollowingId(UUID followingId);
}
