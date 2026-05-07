package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.FriendRequestDto;
import com.musicroom.musicroom.dto.FriendshipDto;
import com.musicroom.musicroom.dto.UserSearchDto;
import java.util.List;
import java.util.UUID;

public interface FriendshipService {
    FriendshipDto sendRequest(UUID requesterId, FriendRequestDto request);
    List<FriendshipDto> getMyFriends(UUID userId);
    List<FriendshipDto> getPendingRequests(UUID userId);
    FriendshipDto acceptRequest(UUID userId, UUID friendshipId);
    FriendshipDto declineRequest(UUID userId, UUID friendshipId);
    void deleteFriend(UUID userId, UUID friendshipId);
    List<UserSearchDto> searchUsers(String name);
}