package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.UserSearchDto;
import java.util.List;
import java.util.UUID;

public interface FollowService {
    void followUser(UUID followerId, UUID followingId);
    void unfollowUser(UUID followerId, UUID followingId);
    boolean isFollowing(UUID followerId, UUID followingId);
    List<UserSearchDto> getFollowers(UUID userId);
    List<UserSearchDto> getFollowing(UUID userId);
}
