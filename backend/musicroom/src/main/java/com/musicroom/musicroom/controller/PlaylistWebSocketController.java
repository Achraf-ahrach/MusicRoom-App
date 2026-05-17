package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.websocket.AddTrackMessage;
import com.musicroom.musicroom.dto.websocket.MoveTrackMessage;
import com.musicroom.musicroom.dto.websocket.RemoveTrackMessage;
import com.musicroom.musicroom.security.JwtTokenProvider;
import com.musicroom.musicroom.service.PlaylistWebSocketService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.util.StringUtils;
import org.springframework.stereotype.Controller;
import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class PlaylistWebSocketController {

    private final PlaylistWebSocketService playlistWebSocketService;
    private final JwtTokenProvider jwtTokenProvider;

    @MessageMapping("/playlist/{playlistId}/add")
    public void addTrack(
            @DestinationVariable UUID playlistId,
            @Payload AddTrackMessage message,
            SimpMessageHeaderAccessor headerAccessor) {
        UUID userId = resolveUserId(headerAccessor);
        playlistWebSocketService.addTrack(playlistId, userId, message);
    }

    @MessageMapping("/playlist/{playlistId}/remove")
    public void removeTrack(
            @DestinationVariable UUID playlistId,
            @Payload RemoveTrackMessage message,
            SimpMessageHeaderAccessor headerAccessor) {
        UUID userId = resolveUserId(headerAccessor);
        playlistWebSocketService.removeTrack(playlistId, userId, message);
    }

    @MessageMapping("/playlist/{playlistId}/move")
    public void moveTrack(
            @DestinationVariable UUID playlistId,
            @Payload MoveTrackMessage message,
            SimpMessageHeaderAccessor headerAccessor) {
        UUID userId = resolveUserId(headerAccessor);
        playlistWebSocketService.moveTrack(playlistId, userId, message);
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