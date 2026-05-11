package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.websocket.VoteMessage;
import com.musicroom.musicroom.dto.websocket.VoteUpdateMessage;
import com.musicroom.musicroom.service.VoteWebSocketService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;
import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class VoteWebSocketController {

    private final VoteWebSocketService voteWebSocketService;

    @MessageMapping("/event/{eventId}/vote")
    public void vote(
            @DestinationVariable UUID eventId,
            @Payload VoteMessage message,
            @AuthenticationPrincipal UserDetails userDetails) {

        UUID userId = UUID.fromString(userDetails.getUsername());
        voteWebSocketService.vote(eventId, userId, message);
    }
}