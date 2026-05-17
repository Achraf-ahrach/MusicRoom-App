package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.*;
import java.util.List;
import java.util.UUID;

import org.springframework.web.multipart.MultipartFile;

public interface PlaylistService {
    PlaylistDto createPlaylist(UUID ownerId, CreatePlaylistRequest request);
    List<PlaylistDto> getMyPlaylists(UUID userId);
    List<PlaylistDto> getPublicPlaylists();
    List<PlaylistDto> getPublicPlaylistsByUser(UUID ownerId);
    PlaylistDto getPlaylistById(UUID playlistId, UUID userId);
    PlaylistDto updatePlaylist(UUID userId, UUID playlistId, CreatePlaylistRequest request);
    void deletePlaylist(UUID userId, UUID playlistId);
    void inviteUser(UUID ownerId, UUID playlistId, InviteToPlaylistRequest request);
    List<PlaylistTrackDto> getPlaylistTracks(UUID playlistId, UUID userId);
    PlaylistDto updatePlaylistCover(UUID userId, UUID playlistId, MultipartFile cover);
    
    void savePlaylist(UUID userId, UUID playlistId);
    void unsavePlaylist(UUID userId, UUID playlistId);
    boolean isPlaylistSaved(UUID userId, UUID playlistId);
    List<PlaylistDto> getSavedPlaylists(UUID userId);

    List<PlaylistCollaboratorDto> getPlaylistCollaborators(UUID playlistId, UUID userId);
    void updateCollaboratorRole(UUID ownerId, UUID playlistId, UUID collaboratorId, String permission);
    void removeCollaborator(UUID ownerId, UUID playlistId, UUID collaboratorId);
}