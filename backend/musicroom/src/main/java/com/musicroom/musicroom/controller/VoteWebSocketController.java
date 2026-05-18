package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.websocket.VoteMessage;
import com.musicroom.musicroom.security.JwtTokenProvider;
import com.musicroom.musicroom.service.VoteWebSocketService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.stereotype.Controller;
import org.springframework.util.StringUtils;
import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class VoteWebSocketController {

    private final VoteWebSocketService voteWebSocketService;
    private final JwtTokenProvider jwtTokenProvider;

    @MessageMapping("/event/{eventId}/vote")
    public void vote(
            @DestinationVariable UUID eventId,
            @Payload VoteMessage message,
            SimpMessageHeaderAccessor headerAccessor) {

        UUID userId = resolveUserId(headerAccessor);
        voteWebSocketService.vote(eventId, userId, message);
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