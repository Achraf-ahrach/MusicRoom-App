package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.UpdatePreferencesRequest;
import com.musicroom.musicroom.dto.UpdateProfileRequest;
import com.musicroom.musicroom.dto.UserProfileDto;
import com.musicroom.musicroom.entity.User;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.repository.FriendshipRepository;
import com.musicroom.musicroom.repository.UserRepository;
import com.musicroom.musicroom.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepo;
    private final FriendshipRepository friendshipRepo;

    @Override
    public UserProfileDto getMyProfile(UUID userId) {

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));


        return UserProfileDto.builder()
                .id(user.getId())
                .displayName(user.getDisplayName())
                .avatarUrl(user.getAvatarUrl())
                .email(user.getEmail())
                .publicInfo(user.getPublicInfo())
                .friendsInfo(user.getFriendsInfo())
                .privateInfo(user.getPrivateInfo())
                .musicPreferences(user.getMusicPreferences())
                .build();
    }

    @Override
    public UserProfileDto getUserProfile(UUID requesterId, UUID targetId) {

        User target = userRepo.findById(targetId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        boolean areFriends =
                friendshipRepo
                        .findByRequesterIdAndStatus(requesterId, "accepted")
                        .stream()
                        .anyMatch(f -> f.getAddressee().getId().equals(targetId))
                ||
                friendshipRepo
                        .findByAddresseeIdAndStatus(requesterId, "accepted")
                        .stream()
                        .anyMatch(f -> f.getRequester().getId().equals(targetId));

        return UserProfileDto.builder()
                .id(target.getId())
                .displayName(target.getDisplayName())
                .avatarUrl(target.getAvatarUrl())
                .publicInfo(target.getPublicInfo())
                .friendsInfo(areFriends ? target.getFriendsInfo() : null)
                .privateInfo(null)
                .musicPreferences(target.getMusicPreferences())
                .build();
    }

    @Override
    @Transactional
    public UserProfileDto updateMyProfile(UUID userId, UpdateProfileRequest request) {

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (request.getDisplayName() != null) {
            user.setDisplayName(request.getDisplayName());
        }
        if (request.getAvatarUrl() != null) {
            user.setAvatarUrl(request.getAvatarUrl());
        }
        if (request.getPublicInfo() != null) {
            user.setPublicInfo(request.getPublicInfo());
        }
        if (request.getFriendsInfo() != null) {
            user.setFriendsInfo(request.getFriendsInfo());
        }
        if (request.getPrivateInfo() != null) {
            user.setPrivateInfo(request.getPrivateInfo());
        }

        userRepo.save(user);
        return getMyProfile(userId);
    }

    @Override
    @Transactional
    public UserProfileDto updatePreferences(UUID userId, UpdatePreferencesRequest request) {

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        user.setMusicPreferences(request.getMusicPreferences());
        userRepo.save(user);
        return getMyProfile(userId);
    }
}