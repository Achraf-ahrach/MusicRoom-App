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
    @Transactional(readOnly = true)
    public List<PlaylistDto> getPublicPlaylists() {
        return playlistRepo.findByVisibility("public")
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public PlaylistDto getPlaylistById(UUID playlistId, UUID userId) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        // vérifier accès
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

        if (request.getName() != null) playlist.setName(request.getName());
        if (request.getDescription() != null) playlist.setDescription(request.getDescription());
        if (request.getVisibility() != null) playlist.setVisibility(request.getVisibility());
        if (request.getLicenseType() != null) playlist.setLicenseType(request.getLicenseType());

        playlistRepo.save(playlist);
        return toDto(playlist);
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

    private PlaylistDto toDto(Playlist playlist) {
        return PlaylistDto.builder()
                .id(playlist.getId())
                .name(playlist.getName())
                .description(playlist.getDescription())
                .visibility(playlist.getVisibility())
                .licenseType(playlist.getLicenseType())
                .version(playlist.getVersion())
                .ownerId(playlist.getOwner().getId())
                .ownerName(playlist.getOwner().getDisplayName())
                .trackCount(playlistTrackRepo.countByPlaylistId(playlist.getId()))
                .createdAt(playlist.getCreatedAt())
                .updatedAt(playlist.getUpdatedAt())
                .build();
    }

    private PlaylistTrackDto toTrackDto(PlaylistTrack pt) {
        return PlaylistTrackDto.builder()
                .id(pt.getId())
                .title(pt.getTrack().getTitle())
                .artist(pt.getTrack().getArtist())
                .album(pt.getTrack().getAlbum())
                .coverUrl(pt.getTrack().getCoverUrl())
                .durationMs(pt.getTrack().getDurationMs())
                .position(pt.getPosition())
                .addedBy(pt.getAddedBy())
                .build();
    }
}