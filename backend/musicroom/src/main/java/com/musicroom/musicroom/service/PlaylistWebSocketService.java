package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.websocket.AddTrackMessage;
import com.musicroom.musicroom.dto.websocket.MoveTrackMessage;
import com.musicroom.musicroom.dto.websocket.PlaylistUpdateMessage;
import com.musicroom.musicroom.dto.websocket.RemoveTrackMessage;
import java.util.UUID;

public interface PlaylistWebSocketService {
    PlaylistUpdateMessage addTrack(UUID playlistId, UUID userId, AddTrackMessage message);
    PlaylistUpdateMessage removeTrack(UUID playlistId, UUID userId, RemoveTrackMessage message);
    PlaylistUpdateMessage moveTrack(UUID playlistId, UUID userId, MoveTrackMessage message);
}