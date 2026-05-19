package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.*;
import com.musicroom.musicroom.entity.*;
import com.musicroom.musicroom.exception.ConflictException;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.exception.UnauthorizedException;
import com.musicroom.musicroom.repository.*;
import com.musicroom.musicroom.service.PlaylistService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.core.Authentication;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import com.musicroom.musicroom.dto.websocket.PlaylistUpdateMessage;
import com.musicroom.musicroom.dto.websocket.PlaylistMessageType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import com.musicroom.musicroom.exception.BadRequestException;
import java.io.IOException;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PlaylistServiceImpl implements PlaylistService {

    private final PlaylistRepository playlistRepo;
    private final PlaylistTrackRepository playlistTrackRepo;
    private final PlaylistInviteRepository inviteRepo;
    private final UserRepository userRepo;
    private final com.musicroom.musicroom.repository.SavedPlaylistRepository savedPlaylistRepo;
    private final SimpMessagingTemplate messagingTemplate;

    @Override
    @Transactional
    public PlaylistDto createPlaylist(UUID ownerId, CreatePlaylistRequest request) {
        User owner = userRepo.findById(ownerId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Playlist playlist = Playlist.builder()
                .owner(owner)
                .name(request.getName())
                .description(request.getDescription())
                .visibility(request.getVisibility() != null ? request.getVisibility() : "public")
                .licenseType(request.getLicenseType() != null ? request.getLicenseType() : "open")
                .version(0)
                .build();

        playlistRepo.save(playlist);
        return toDto(playlist);
    }

    @Override
    @Transactional(readOnly = true)
    public List<PlaylistDto> getMyPlaylists(UUID userId) {
        return playlistRepo.findAccessibleByUserId(userId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public PlaylistDto updatePlaylistCover(UUID userId, UUID playlistId,
                                            MultipartFile cover) {

        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        if (!playlist.getOwner().getId().equals(userId)) {
            throw new UnauthorizedException("Not authorized to update this playlist");
        }

        if (cover != null && !cover.isEmpty()) {

            String contentType = cover.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                throw new BadRequestException("Le fichier doit être une image");
            }

            if (cover.getSize() > 2 * 1024 * 1024) {
                throw new BadRequestException("L'image ne doit pas dépasser 2MB");
            }

            try {
                byte[] bytes = cover.getBytes();
                String base64 = java.util.Base64.getEncoder()
                        .encodeToString(bytes);
                String dataUrl = "data:" + contentType + ";base64," + base64;
                playlist.setCoverUrl(dataUrl);
            } catch (IOException e) {
                throw new BadRequestException("Erreur lors de l'upload de l'image");
            }
        }

        playlistRepo.save(playlist);
        return toDto(playlist);
    }

    @Override
    @Transactional(readOnly = true)
    public List<PlaylistDto> getPublicPlaylists() {
        return playlistRepo.findByVisibility("public")
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<PlaylistDto> getPublicPlaylistsByUser(UUID ownerId) {
        return playlistRepo.findByOwnerIdAndVisibility(ownerId, "public")
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public PlaylistDto getPlaylistById(UUID playlistId, UUID userId) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        if (playlist.getVisibility().equals("private") &&
            !playlist.getOwner().getId().equals(userId) &&
            !inviteRepo.existsByPlaylistIdAndUserId(playlistId, userId)) {
            throw new UnauthorizedException("Access denied to this playlist");
        }

        return toDto(playlist);
    }

    @Override
    @Transactional
    public PlaylistDto updatePlaylist(UUID userId, UUID playlistId,
                                      CreatePlaylistRequest request) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        if (!playlist.getOwner().getId().equals(userId)) {
            throw new UnauthorizedException("Not authorized to update this playlist");
        }

        String oldVisibility = playlist.getVisibility();
        if (request.getName() != null) playlist.setName(request.getName());
        if (request.getDescription() != null) playlist.setDescription(request.getDescription());
        if (request.getVisibility() != null) playlist.setVisibility(request.getVisibility());
        if (request.getLicenseType() != null) playlist.setLicenseType(request.getLicenseType());

        playlistRepo.save(playlist);
        PlaylistDto dto = toDto(playlist);

        boolean visibilityChanged = request.getVisibility() != null && !request.getVisibility().equals(oldVisibility);
        PlaylistMessageType msgType = visibilityChanged ? PlaylistMessageType.VISIBILITY_CHANGED : PlaylistMessageType.PLAYLIST_RELOADED;

        PlaylistUpdateMessage wsMsg = PlaylistUpdateMessage.builder()
                .type(msgType)
                .playlistId(playlistId)
                .version(playlist.getVersion())
                .userId(userId)
                .message(playlist.getVisibility())
                .build();
        messagingTemplate.convertAndSend("/topic/playlist/" + playlistId, wsMsg);

        return dto;
    }

    @Override
    @Transactional
    public void deletePlaylist(UUID userId, UUID playlistId) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        if (!playlist.getOwner().getId().equals(userId)) {
            throw new UnauthorizedException("Not authorized to delete this playlist");
        }

        playlistRepo.delete(playlist);
    }

    @Override
    @Transactional
    public void inviteUser(UUID ownerId, UUID playlistId,
                           InviteToPlaylistRequest request) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        if (!playlist.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException("Not authorized to invite users");
        }

        if (inviteRepo.existsByPlaylistIdAndUserId(playlistId, request.getUserId())) {
            throw new ConflictException("User already invited to this playlist");
        }

        User user = userRepo.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        PlaylistInvite invite = new PlaylistInvite();
        invite.setPlaylist(playlist);
        invite.setUser(user);
        invite.setPermission(request.getPermission() != null ? request.getPermission() : "editor");
        inviteRepo.save(invite);

        PlaylistUpdateMessage wsMsg = PlaylistUpdateMessage.builder()
                .type(PlaylistMessageType.COLLABORATOR_INVITED)
                .playlistId(playlistId)
                .userId(ownerId)
                .message(request.getUserId().toString())
                .build();
        messagingTemplate.convertAndSend("/topic/playlist/" + playlistId, wsMsg);
    }

    @Override
    @Transactional(readOnly = true)
    public List<PlaylistTrackDto> getPlaylistTracks(UUID playlistId, UUID userId) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        if (playlist.getVisibility().equals("private") &&
            !playlist.getOwner().getId().equals(userId) &&
            !inviteRepo.existsByPlaylistIdAndUserId(playlistId, userId)) {
            throw new UnauthorizedException("Access denied to this playlist");
        }

        return playlistTrackRepo.findByPlaylistIdOrderByPosition(playlistId)
                .stream()
                .map(this::toTrackDto)
                .collect(Collectors.toList());
    }

    private String getCurrentUserIdString() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetails) {
            return ((UserDetails) auth.getPrincipal()).getUsername();
        }
        return null;
    }

    private PlaylistDto toDto(Playlist playlist) {
        String coverUrl = null;
        List<PlaylistTrack> tracks = playlistTrackRepo.findByPlaylistIdOrderByPosition(playlist.getId());
        if (tracks != null && !tracks.isEmpty()) {
            coverUrl = tracks.get(0).getTrack().getCoverUrl();
        }

        String permission = null;
        try {
            String currentUserIdStr = getCurrentUserIdString();
            if (currentUserIdStr != null) {
                UUID currentUserId = UUID.fromString(currentUserIdStr);
                if (playlist.getOwner().getId().equals(currentUserId)) {
                    permission = "owner";
                } else {
                    permission = inviteRepo.findByPlaylistIdAndUserId(playlist.getId(), currentUserId)
                            .map(PlaylistInvite::getPermission)
                            .orElse(null);
                }
            }
        } catch (Exception e) {
            // Ignore context exceptions
        }

        return PlaylistDto.builder()
                .id(playlist.getId())
                .name(playlist.getName())
                .description(playlist.getDescription())
                .visibility(playlist.getVisibility())
                .licenseType(playlist.getLicenseType())
                .version(playlist.getVersion())
                .ownerId(playlist.getOwner().getId())
                .ownerName(playlist.getOwner().getDisplayName())
                .trackCount(tracks != null ? tracks.size() : 0)
                .createdAt(playlist.getCreatedAt())
                .updatedAt(playlist.getUpdatedAt())
                .coverUrl(coverUrl)
                .permission(permission)
                .build();
    }

    private PlaylistTrackDto toTrackDto(PlaylistTrack pt) {
        return PlaylistTrackDto.builder()
                .id(pt.getId())
                .externalId(pt.getTrack().getExternalId())
                .title(pt.getTrack().getTitle())
                .artist(pt.getTrack().getArtist())
                .album(pt.getTrack().getAlbum())
                .coverUrl(pt.getTrack().getCoverUrl())
                .durationMs(pt.getTrack().getDurationMs())
                .position(pt.getPosition())
                .addedBy(pt.getAddedBy())
                .build();
    }

    @Override
    @Transactional
    public void savePlaylist(UUID userId, UUID playlistId) {
        if (!savedPlaylistRepo.existsByUserIdAndPlaylistId(userId, playlistId)) {
            User user = userRepo.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
            Playlist playlist = playlistRepo.findById(playlistId).orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));
            
            SavedPlaylist savedPlaylist = new SavedPlaylist();
            savedPlaylist.setUser(user);
            savedPlaylist.setPlaylist(playlist);
            savedPlaylistRepo.save(savedPlaylist);
        }
    }

    @Override
    @Transactional
    public void unsavePlaylist(UUID userId, UUID playlistId) {
        savedPlaylistRepo.findByUserIdAndPlaylistId(userId, playlistId)
                .ifPresent(savedPlaylistRepo::delete);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isPlaylistSaved(UUID userId, UUID playlistId) {
        return savedPlaylistRepo.existsByUserIdAndPlaylistId(userId, playlistId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<PlaylistDto> getSavedPlaylists(UUID userId) {
        return savedPlaylistRepo.findByUserId(userId)
                .stream()
                .map(sp -> toDto(sp.getPlaylist()))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<PlaylistCollaboratorDto> getPlaylistCollaborators(UUID playlistId, UUID userId) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        if (playlist.getVisibility().equals("private") &&
            !playlist.getOwner().getId().equals(userId) &&
            !inviteRepo.existsByPlaylistIdAndUserId(playlistId, userId)) {
            throw new UnauthorizedException("Access denied to this playlist");
        }

        return inviteRepo.findByPlaylistId(playlistId)
                .stream()
                .map(invite -> PlaylistCollaboratorDto.builder()
                        .userId(invite.getUser().getId())
                        .displayName(invite.getUser().getDisplayName())
                        .avatarUrl(invite.getUser().getAvatarUrl())
                        .permission(invite.getPermission())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void updateCollaboratorRole(UUID ownerId, UUID playlistId, UUID collaboratorId, String permission) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        if (!playlist.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException("Only the playlist owner can change roles");
        }

        PlaylistInvite invite = inviteRepo.findByPlaylistIdAndUserId(playlistId, collaboratorId)
                .orElseThrow(() -> new ResourceNotFoundException("Collaborator not found"));

        invite.setPermission(permission);
        inviteRepo.save(invite);

        PlaylistUpdateMessage wsMsg = PlaylistUpdateMessage.builder()
                .type(PlaylistMessageType.ROLE_CHANGED)
                .playlistId(playlistId)
                .userId(ownerId)
                .message(collaboratorId.toString())
                .build();
        messagingTemplate.convertAndSend("/topic/playlist/" + playlistId, wsMsg);
    }

    @Override
    @Transactional
    public void removeCollaborator(UUID ownerId, UUID playlistId, UUID collaboratorId) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        if (!playlist.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException("Only the playlist owner can remove collaborators");
        }

        PlaylistInvite invite = inviteRepo.findByPlaylistIdAndUserId(playlistId, collaboratorId)
                .orElseThrow(() -> new ResourceNotFoundException("Collaborator not found"));

        inviteRepo.delete(invite);

        PlaylistUpdateMessage wsMsg = PlaylistUpdateMessage.builder()
                .type(PlaylistMessageType.COLLABORATOR_REMOVED)
                .playlistId(playlistId)
                .userId(ownerId)
                .message(collaboratorId.toString())
                .build();
        messagingTemplate.convertAndSend("/topic/playlist/" + playlistId, wsMsg);
    }
}