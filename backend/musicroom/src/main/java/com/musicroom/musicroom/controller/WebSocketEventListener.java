package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.repository.UserRepository;
import com.musicroom.musicroom.repository.EventRepository;
import com.musicroom.musicroom.security.JwtTokenProvider;
import com.musicroom.musicroom.service.PlaybackService;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;
import org.springframework.web.socket.messaging.SessionSubscribeEvent;
import org.springframework.web.socket.messaging.SessionUnsubscribeEvent;

import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;


@Component
@RequiredArgsConstructor
@Slf4j
public class WebSocketEventListener {

    private final SimpMessagingTemplate messagingTemplate;
    private final UserRepository userRepo;
    private final EventRepository eventRepo;
    private final JwtTokenProvider jwtTokenProvider;
    private final PlaybackService playbackService;
    
    @org.springframework.beans.factory.annotation.Autowired
    @org.springframework.context.annotation.Lazy
    private com.musicroom.musicroom.service.EventService eventService;

    private final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();

    // Map of eventId -> Set of sessionIds
    private final Map<UUID, Set<String>> roomListeners = new ConcurrentHashMap<>();
    // Map of sessionId -> eventId (to clean up on disconnect)
    private final Map<String, UUID> sessionRooms = new ConcurrentHashMap<>();
    // Map of eventId -> Map of sessionId -> User details map
    private final Map<UUID, Map<String, Map<String, Object>>> roomUserListeners = new ConcurrentHashMap<>();

    @PreDestroy
    public void shutdown() {
        scheduler.shutdown();
    }

    @EventListener
    public void handleSessionSubscribe(SessionSubscribeEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String destination = headerAccessor.getDestination();
        String sessionId = headerAccessor.getSessionId();

        if (destination != null && destination.startsWith("/topic/event/") && destination.endsWith("/listeners")) {
            try {
                // destination pattern: /topic/event/{eventId}/listeners
                String[] parts = destination.split("/");
                if (parts.length >= 4) {
                    UUID eventId = UUID.fromString(parts[3]);
                    roomListeners.computeIfAbsent(eventId, k -> ConcurrentHashMap.newKeySet()).add(sessionId);
                    sessionRooms.put(sessionId, eventId);

                    // Track user details of the listener
                    try {
                        java.security.Principal principal = headerAccessor.getUser();
                        String userIdStr = null;
                        if (principal != null) {
                            userIdStr = principal.getName();
                        } else {
                            String authHeader = headerAccessor.getFirstNativeHeader("Authorization");
                            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                                String token = authHeader.substring(7);
                                userIdStr = jwtTokenProvider.getUserIdFromToken(token);
                            }
                        }
                        if (userIdStr != null) {
                            userRepo.findById(UUID.fromString(userIdStr)).ifPresent(user -> {
                                Map<String, Object> userMap = new HashMap<>();
                                userMap.put("userId", user.getId().toString());
                                userMap.put("displayName", user.getDisplayName());
                                userMap.put("avatarUrl", user.getAvatarUrl() != null ? user.getAvatarUrl() : "");
                                roomUserListeners.computeIfAbsent(eventId, k -> new ConcurrentHashMap<>()).put(sessionId, userMap);
                                log.info("User {} registered as active listener in room {}", user.getDisplayName(), eventId);
                            });
                        }
                    } catch (Exception ex) {
                        log.warn("Could not register active listener user details: {}", ex.getMessage());
                    }

                    int count = getListenerCount(eventId);
                    broadcastListenerCount(eventId, count);
                }
            } catch (Exception e) {
                log.error("Error processing subscribe event", e);
            }
        }
    }

    @EventListener
    public void handleSessionUnsubscribe(SessionUnsubscribeEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();
        cleanUpSession(sessionId);
    }

    @EventListener
    public void handleSessionDisconnect(SessionDisconnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();
        cleanUpSession(sessionId);
    }

    private void cleanUpSession(String sessionId) {
        UUID eventId = sessionRooms.remove(sessionId);
        if (eventId != null) {
            // Remove user details from roomUserListeners
            Map<String, Map<String, Object>> userListeners = roomUserListeners.get(eventId);
            if (userListeners != null) {
                userListeners.remove(sessionId);
                if (userListeners.isEmpty()) {
                    roomUserListeners.remove(eventId);
                }
            }

            Set<String> sessions = roomListeners.get(eventId);
            if (sessions != null) {
                sessions.remove(sessionId);
                int count = getListenerCount(eventId);
                broadcastListenerCount(eventId, count);

                // When all listeners leave, delete the event entirely
                if (sessions.isEmpty()) {
                    roomListeners.remove(eventId);
                    log.info("All listeners left event {}, deleting it", eventId);

                    // Stop the playback engine
                    if (playbackService.isEventPlaying(eventId)) {
                        playbackService.stopEvent(eventId);
                    }

                    // Delete the event
                    eventService.deleteEventSystem(eventId);
                }
            }
        }
    }

    public List<Map<String, Object>> getActiveListeners(UUID eventId) {
        Map<String, Map<String, Object>> listeners = roomUserListeners.get(eventId);
        if (listeners == null) {
            return java.util.Collections.emptyList();
        }
        // Deduplicate by userId
        Map<String, Map<String, Object>> uniqueUsers = new java.util.LinkedHashMap<>();
        for (Map<String, Object> user : listeners.values()) {
            String userId = (String) user.get("userId");
            if (userId != null) {
                uniqueUsers.put(userId, user);
            }
        }
        return new java.util.ArrayList<>(uniqueUsers.values());
    }

    public int getListenerCount(UUID eventId) {
        Set<String> sessions = roomListeners.get(eventId);
        if (sessions == null || sessions.isEmpty()) {
            return 0;
        }
        
        Map<String, Map<String, Object>> userListeners = roomUserListeners.get(eventId);
        Set<String> uniqueUserIds = new java.util.HashSet<>();
        int anonymousCount = 0;
        
        for (String sessId : sessions) {
            if (userListeners != null && userListeners.containsKey(sessId)) {
                String userId = (String) userListeners.get(sessId).get("userId");
                if (userId != null) {
                    uniqueUserIds.add(userId);
                } else {
                    anonymousCount++;
                }
            } else {
                anonymousCount++;
            }
        }
        return uniqueUserIds.size() + anonymousCount;
    }

    private void broadcastListenerCount(UUID eventId, int count) {
        Map<String, Object> payload = Map.of("count", count);
        messagingTemplate.convertAndSend("/topic/event/" + eventId + "/listeners", payload);
        
        // Only broadcast globally if the event is public
        boolean isPublic = eventRepo.findById(eventId)
                .map(event -> "public".equalsIgnoreCase(event.getVisibility()))
                .orElse(false);

        if (isPublic) {
            try {
                messagingTemplate.convertAndSend("/topic/events", Map.of(
                    "type", "LISTENER_COUNT_CHANGED",
                    "eventId", eventId.toString(),
                    "count", count
                ));
            } catch (Exception e) {
                log.error("Failed to broadcast LISTENER_COUNT_CHANGED to /topic/events", e);
            }
        }
    }
}
