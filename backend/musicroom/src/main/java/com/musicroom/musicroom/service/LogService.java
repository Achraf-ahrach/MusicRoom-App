package com.musicroom.musicroom.service;

import java.util.Map;
import java.util.UUID;

public interface LogService {

    // Generic method to save logs

    public void saveLog(UUID userId, UUID deviceId, String action, String platform, 
                        String appVersion, String ipAddress, Map<String, Object> metadata);

    // Log user login

    public void logUserLogin(UUID userId, String platform, String ipAddress);

    // Log user registration

    public void logUserRegister(UUID userId, String email, String platform, String ipAddress);

    // Log playlist created

    public void logPlaylistCreated(UUID userId, UUID playlistId, String playlistName, String ipAddress);

    // Log music added to playlist

    public void logMusicAdded(UUID userId, UUID playlistId, UUID musicId, String musicName, String ipAddress);

    // Log music removed from playlist

    public void logMusicRemoved(UUID userId, UUID playlistId, UUID musicId, String musicName, String ipAddress);

    // Log playlist deleted

    public void logPlaylistDeleted(UUID userId, UUID playlistId, String playlistName, String ipAddress);

    // Log delegation created

    public void logDelegationCreated(UUID userId, UUID delegateId, String delegateEmail, 
                                     UUID resourceId, String resourceType, String permission, String ipAddress);

    // Log delegation permission updated

    public void logDelegationPermissionUpdated(UUID userId, UUID delegationId, UUID delegateId, 
                                               String delegateEmail, UUID resourceId, String resourceType,
                                               String oldPermission, String newPermission, String ipAddress);

    // Log delegation removed

    public void logDelegationRemoved(UUID userId, UUID delegationId, UUID delegateId, 
                                     String delegateEmail, UUID resourceId, String resourceType, 
                                     String permission, String ipAddress);

    // Log event room created

    public void logEventRoomCreated(UUID userId, UUID eventRoomId, String roomName, String ipAddress);

    // Log device connected

    public void logDeviceConnected(UUID userId, UUID deviceId, String deviceName, String platform, String ipAddress);
}
