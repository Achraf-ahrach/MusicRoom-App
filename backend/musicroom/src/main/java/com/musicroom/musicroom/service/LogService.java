package com.musicroom.musicroom.service;

import com.musicroom.musicroom.entity.Log;
import com.musicroom.musicroom.repository.LogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LogService {

    private final LogRepository logRepository;

    /**
     * Generic method to save logs
     */
    public void saveLog(UUID userId, UUID deviceId, String action, String platform, 
                        String appVersion, String ipAddress, Map<String, Object> metadata) {
        Log log = Log.builder()
                .userId(userId)
                .deviceId(deviceId)
                .action(action)
                .platform(platform)
                .appVersion(appVersion)
                .ipAddress(ipAddress)
                .metadata(metadata != null ? metadata : new HashMap<>())
                .createdAt(LocalDateTime.now())
                .build();

        logRepository.save(log);
    }

    /**
     * Log user login
     */
    public void logUserLogin(UUID userId, String platform, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "USER_LOGIN", platform, null, ipAddress, metadata);
    }

    /**
     * Log user registration
     */
    public void logUserRegister(UUID userId, String email, String platform, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("email", email);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "USER_REGISTER", platform, null, ipAddress, metadata);
    }

    /**
     * Log playlist created
     */
    public void logPlaylistCreated(UUID userId, UUID playlistId, String playlistName, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("playlistId", playlistId.toString());
        metadata.put("playlistName", playlistName);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "PLAYLIST_CREATED", null, null, ipAddress, metadata);
    }

    /**
     * Log music added to playlist
     */
    public void logMusicAdded(UUID userId, UUID playlistId, UUID musicId, String musicName, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("playlistId", playlistId.toString());
        metadata.put("musicId", musicId.toString());
        metadata.put("musicName", musicName);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "MUSIC_ADDED", null, null, ipAddress, metadata);
    }

    /**
     * Log music removed from playlist
     */
    public void logMusicRemoved(UUID userId, UUID playlistId, UUID musicId, String musicName, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("playlistId", playlistId.toString());
        metadata.put("musicId", musicId.toString());
        metadata.put("musicName", musicName);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "MUSIC_REMOVED", null, null, ipAddress, metadata);
    }

    /**
     * Log playlist deleted
     */
    public void logPlaylistDeleted(UUID userId, UUID playlistId, String playlistName, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("playlistId", playlistId.toString());
        metadata.put("playlistName", playlistName);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "PLAYLIST_DELETED", null, null, ipAddress, metadata);
    }

    /**
     * Log delegation created
     */
    public void logDelegationCreated(UUID userId, UUID delegateId, String delegateEmail, 
                                     UUID resourceId, String resourceType, String permission, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("delegateId", delegateId.toString());
        metadata.put("delegateEmail", delegateEmail);
        metadata.put("resourceId", resourceId.toString());
        metadata.put("resourceType", resourceType);
        metadata.put("permission", permission);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "DELEGATION_CREATED", null, null, ipAddress, metadata);
    }

    /**
     * Log delegation permission updated
     */
    public void logDelegationPermissionUpdated(UUID userId, UUID delegationId, UUID delegateId, 
                                               String delegateEmail, UUID resourceId, String resourceType,
                                               String oldPermission, String newPermission, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("delegationId", delegationId.toString());
        metadata.put("delegateId", delegateId.toString());
        metadata.put("delegateEmail", delegateEmail);
        metadata.put("resourceId", resourceId.toString());
        metadata.put("resourceType", resourceType);
        metadata.put("oldPermission", oldPermission);
        metadata.put("newPermission", newPermission);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "DELEGATION_PERMISSION_UPDATED", null, null, ipAddress, metadata);
    }

    /**
     * Log delegation removed
     */
    public void logDelegationRemoved(UUID userId, UUID delegationId, UUID delegateId, 
                                     String delegateEmail, UUID resourceId, String resourceType, 
                                     String permission, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("delegationId", delegationId.toString());
        metadata.put("delegateId", delegateId.toString());
        metadata.put("delegateEmail", delegateEmail);
        metadata.put("resourceId", resourceId.toString());
        metadata.put("resourceType", resourceType);
        metadata.put("permission", permission);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "DELEGATION_REMOVED", null, null, ipAddress, metadata);
    }

    /**
     * Log event room created
     */
    public void logEventRoomCreated(UUID userId, UUID eventRoomId, String roomName, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("eventRoomId", eventRoomId.toString());
        metadata.put("roomName", roomName);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, null, "EVENT_ROOM_CREATED", null, null, ipAddress, metadata);
    }

    /**
     * Log device connected
     */
    public void logDeviceConnected(UUID userId, UUID deviceId, String deviceName, String platform, String ipAddress) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("deviceName", deviceName);
        metadata.put("platform", platform);
        metadata.put("timestamp", LocalDateTime.now().toString());
        
        saveLog(userId, deviceId, "DEVICE_CONNECTED", platform, null, ipAddress, metadata);
    }
}
