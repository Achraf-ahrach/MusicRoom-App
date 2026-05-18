package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.websocket.PlaybackMessage;
import com.musicroom.musicroom.entity.Event;
import com.musicroom.musicroom.repository.EventRepository;
import com.musicroom.musicroom.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.util.StringUtils;

import java.util.UUID;

@Controller
@RequiredArgsConstructor
@Slf4j
public class PlaybackWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final EventRepository eventRepository;
    private final JwtTokenProvider jwtTokenProvider;

    @MessageMapping("/event/{eventId}/playback")
    public void handlePlayback(
            @DestinationVariable UUID eventId,
            @Payload PlaybackMessage message,
            SimpMessageHeaderAccessor headerAccessor) {

        UUID userId = resolveUserId(headerAccessor);

        // Verify if user is the owner of the event
        Event event = eventRepository.findById(eventId)
                .orElse(null);

        if (event == null) {
            log.warn("Playback sync request for non-existent event: {}", eventId);
            return;
        }

        if (!event.getOwner().getId().equals(userId)) {
            log.warn("User {} attempted to control playback for event {} but is not the owner", userId, eventId);
            return;
        }

        log.info("Broadcasting playback start for event {}: {} by {}", eventId, message.getTitle(), message.getArtist());

        // Broadcast to all listeners of the event
        messagingTemplate.convertAndSend("/topic/event/" + eventId + "/playback", message);
    }

    private UUID resolveUserId(SimpMessageHeaderAccessor headerAccessor) {
        Object authHeader = headerAccessor.getFirstNativeHeader("Authorization");
        if (authHeader == null) {
            throw new IllegalArgumentException("Missing Authorization header");
        }
        String authValue = authHeader.toString();
        if (!StringUtils.hasText(authValue) || !authValue.startsWith("Bearer ")) {
            throw new IllegalArgumentException("Invalid Authorization header");
        }
        String token = authValue.substring(7);
        if (!jwtTokenProvider.validateToken(token)) {
            throw new IllegalArgumentException("Invalid token");
        }
        return UUID.fromString(jwtTokenProvider.getUserIdFromToken(token));
    }
}
