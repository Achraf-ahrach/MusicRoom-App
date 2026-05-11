package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.*;
import java.util.List;
import java.util.UUID;

public interface PlaylistService {
    PlaylistDto createPlaylist(UUID ownerId, CreatePlaylistRequest request);
    List<PlaylistDto> getMyPlaylists(UUID userId);
    List<PlaylistDto> getPublicPlaylists();
    PlaylistDto getPlaylistById(UUID playlistId, UUID userId);
    PlaylistDto updatePlaylist(UUID userId, UUID playlistId, CreatePlaylistRequest request);
    void deletePlaylist(UUID userId, UUID playlistId);
    void inviteUser(UUID ownerId, UUID playlistId, InviteToPlaylistRequest request);
    List<PlaylistTrackDto> getPlaylistTracks(UUID playlistId, UUID userId);
}