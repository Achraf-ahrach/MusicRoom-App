package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.UpdatePreferencesRequest;
import com.musicroom.musicroom.dto.UpdateProfileRequest;
import com.musicroom.musicroom.dto.UserProfileDto;
import java.util.UUID;

public interface UserService {
    UserProfileDto getMyProfile(UUID userId);
    UserProfileDto getUserProfile(UUID requesterId, UUID targetId);
    UserProfileDto updateMyProfile(UUID userId, UpdateProfileRequest request);
    UserProfileDto updatePreferences(UUID userId, UpdatePreferencesRequest request);
}
