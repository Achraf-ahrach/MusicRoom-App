package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.UserSearchDto;
import com.musicroom.musicroom.entity.User;
import com.musicroom.musicroom.entity.UserFollow;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.exception.BadRequestException;
import com.musicroom.musicroom.repository.UserFollowRepository;
import com.musicroom.musicroom.repository.UserRepository;
import com.musicroom.musicroom.service.FollowService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FollowServiceImpl implements FollowService {

    private final UserFollowRepository userFollowRepo;
    private final UserRepository userRepo;

    @Override
    @Transactional
    public void followUser(UUID followerId, UUID followingId) {
        if (followerId.equals(followingId)) {
            throw new BadRequestException("You cannot follow yourself");
        }

        if (!userFollowRepo.existsByFollowerIdAndFollowingId(followerId, followingId)) {
            User follower = userRepo.findById(followerId).orElseThrow(() -> new ResourceNotFoundException("Follower not found"));
            User following = userRepo.findById(followingId).orElseThrow(() -> new ResourceNotFoundException("Following user not found"));

            UserFollow follow = new UserFollow();
            follow.setFollower(follower);
            follow.setFollowing(following);
            userFollowRepo.save(follow);
        }
    }

    @Override
    @Transactional
    public void unfollowUser(UUID followerId, UUID followingId) {
        userFollowRepo.findByFollowerIdAndFollowingId(followerId, followingId)
                .ifPresent(userFollowRepo::delete);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isFollowing(UUID followerId, UUID followingId) {
        return userFollowRepo.existsByFollowerIdAndFollowingId(followerId, followingId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserSearchDto> getFollowers(UUID userId) {
        return userFollowRepo.findByFollowingId(userId)
                .stream()
                .map(uf -> toDto(uf.getFollower()))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserSearchDto> getFollowing(UUID userId) {
        return userFollowRepo.findByFollowerId(userId)
                .stream()
                .map(uf -> toDto(uf.getFollowing()))
                .collect(Collectors.toList());
    }

    private UserSearchDto toDto(User user) {
        return UserSearchDto.builder()
                .id(user.getId())
                .displayName(user.getDisplayName())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
}
