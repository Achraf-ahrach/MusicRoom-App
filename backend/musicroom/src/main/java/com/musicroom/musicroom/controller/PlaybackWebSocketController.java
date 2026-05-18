package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.websocket.PlaybackMessage;
import com.musicroom.musicroom.security.JwtTokenProvider;
import com.musicroom.musicroom.service.PlaybackService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.stereotype.Controller;
import org.springframework.util.StringUtils;

import java.util.UUID;

@Controller
@RequiredArgsConstructor
@Slf4j
public class PlaybackWebSocketController {

    private final PlaybackService playbackService;
    private final JwtTokenProvider jwtTokenProvider;

    /**
     * Handle playback commands from clients.
     * Only START_EVENT is accepted — once started, the server manages everything.
     * PAUSE / STOP / SEEK commands are ignored (music cannot be stopped).
     */
    @MessageMapping("/event/{eventId}/playback")
    public void handlePlayback(
            @DestinationVariable UUID eventId,
            @Payload PlaybackMessage message,
            SimpMessageHeaderAccessor headerAccessor) {

        UUID userId = resolveUserId(headerAccessor);
        String command = message.getCommand();

        if ("START_EVENT".equals(command)) {
            log.info("User {} requesting to start event {}", userId, eventId);
            playbackService.startEvent(eventId, userId);
        } else {
            // All other commands (PAUSE, STOP, SEEK, PLAY) are ignored
            // The server is the sole controller of playback
            log.debug("Ignoring client playback command '{}' for event {} from user {} — server controls playback",
                    command, eventId, userId);
        }
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
