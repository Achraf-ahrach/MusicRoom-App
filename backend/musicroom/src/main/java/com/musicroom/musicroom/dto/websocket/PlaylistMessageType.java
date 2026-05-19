package com.musicroom.musicroom.dto.websocket;

public enum PlaylistMessageType {
    TRACK_ADDED,
    TRACK_REMOVED,
    TRACK_MOVED,
    CONFLICT,
    PLAYLIST_RELOADED,
    VISIBILITY_CHANGED,
    ROLE_CHANGED,
    COLLABORATOR_INVITED,
    COLLABORATOR_REMOVED
}