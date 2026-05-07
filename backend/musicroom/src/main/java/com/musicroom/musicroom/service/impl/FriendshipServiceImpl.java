package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.FriendRequestDto;
import com.musicroom.musicroom.dto.FriendshipDto;
import com.musicroom.musicroom.dto.UserSearchDto;
import com.musicroom.musicroom.entity.Friendship;
import com.musicroom.musicroom.entity.User;
import com.musicroom.musicroom.exception.ConflictException;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.exception.UnauthorizedException;
import com.musicroom.musicroom.repository.FriendshipRepository;
import com.musicroom.musicroom.repository.UserRepository;
import com.musicroom.musicroom.service.FriendshipService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FriendshipServiceImpl implements FriendshipService {

    private final FriendshipRepository friendshipRepo;
    private final UserRepository userRepo;

    @Override
    @Transactional
    public FriendshipDto sendRequest(UUID requesterId, FriendRequestDto request) {

        if (requesterId.equals(request.getAddresseeId())) {
            throw new ConflictException("You cannot send a friend request to yourself");
        }

        User requester = userRepo.findById(requesterId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        User addressee = userRepo.findById(request.getAddresseeId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // vérifier si une demande existe déjà dans les deux sens
        if (friendshipRepo.existsByRequesterIdAndAddresseeId(requesterId, request.getAddresseeId()) ||
            friendshipRepo.existsByRequesterIdAndAddresseeId(request.getAddresseeId(), requesterId)) {
            throw new ConflictException("Friend request already exists");
        }

        Friendship friendship = Friendship.builder()
                .requester(requester)
                .addressee(addressee)
                .status("pending")
                .build();

        friendshipRepo.save(friendship);
        return toDto(friendship);
    }

    @Override
    public List<FriendshipDto> getMyFriends(UUID userId) {
        return friendshipRepo.findAllByUserIdAndStatus(userId, "accepted")
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    public List<FriendshipDto> getPendingRequests(UUID userId) {
        return friendshipRepo.findByAddresseeIdAndStatus(userId, "pending")
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public FriendshipDto acceptRequest(UUID userId, UUID friendshipId) {

        Friendship friendship = friendshipRepo.findById(friendshipId)
                .orElseThrow(() -> new ResourceNotFoundException("Friend request not found"));

        if (!friendship.getAddressee().getId().equals(userId)) {
            throw new UnauthorizedException("Not authorized to accept this request");
        }

        if (!friendship.getStatus().equals("pending")) {
            throw new ConflictException("Request is not pending");
        }

        friendship.setStatus("accepted");
        friendshipRepo.save(friendship);
        return toDto(friendship);
    }

    @Override
    @Transactional
    public FriendshipDto declineRequest(UUID userId, UUID friendshipId) {

        Friendship friendship = friendshipRepo.findById(friendshipId)
                .orElseThrow(() -> new ResourceNotFoundException("Friend request not found"));

        if (!friendship.getAddressee().getId().equals(userId)) {
            throw new UnauthorizedException("Not authorized to decline this request");
        }

        friendship.setStatus("declined");
        friendshipRepo.save(friendship);
        return toDto(friendship);
    }

    @Override
    @Transactional
    public void deleteFriend(UUID userId, UUID friendshipId) {

        Friendship friendship = friendshipRepo.findById(friendshipId)
                .orElseThrow(() -> new ResourceNotFoundException("Friendship not found"));

        if (!friendship.getRequester().getId().equals(userId) &&
            !friendship.getAddressee().getId().equals(userId)) {
            throw new UnauthorizedException("Not authorized to delete this friendship");
        }

        friendshipRepo.delete(friendship);
    }

    @Override
    public List<UserSearchDto> searchUsers(String name) {
        return userRepo.findByDisplayNameContainingIgnoreCase(name)
                .stream()
                .map(u -> UserSearchDto.builder()
                        .id(u.getId())
                        .displayName(u.getDisplayName())
                        .avatarUrl(u.getAvatarUrl())
                        .build())
                .collect(Collectors.toList());
    }

    private FriendshipDto toDto(Friendship f) {
        return FriendshipDto.builder()
                .id(f.getId())
                .requesterId(f.getRequester().getId())
                .requesterName(f.getRequester().getDisplayName())
                .requesterAvatar(f.getRequester().getAvatarUrl())
                .addresseeId(f.getAddressee().getId())
                .addresseeName(f.getAddressee().getDisplayName())
                .addresseeAvatar(f.getAddressee().getAvatarUrl())
                .status(f.getStatus())
                .createdAt(f.getCreatedAt())
                .build();
    }
}