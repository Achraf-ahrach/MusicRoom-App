package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.websocket.AddTrackMessage;
import com.musicroom.musicroom.dto.websocket.MoveTrackMessage;
import com.musicroom.musicroom.dto.websocket.PlaylistUpdateMessage;
import com.musicroom.musicroom.dto.websocket.RemoveTrackMessage;
import com.musicroom.musicroom.service.PlaylistWebSocketService;
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
public class PlaylistWebSocketController {

    private final PlaylistWebSocketService playlistWebSocketService;

    @MessageMapping("/playlist/{playlistId}/add")
    public void addTrack(
            @DestinationVariable UUID playlistId,
            @Payload AddTrackMessage message,
            @AuthenticationPrincipal UserDetails userDetails) {

        UUID userId = UUID.fromString(userDetails.getUsername());
        playlistWebSocketService.addTrack(playlistId, userId, message);
    }

    @MessageMapping("/playlist/{playlistId}/remove")
    public void removeTrack(
            @DestinationVariable UUID playlistId,
            @Payload RemoveTrackMessage message,
            @AuthenticationPrincipal UserDetails userDetails) {

        UUID userId = UUID.fromString(userDetails.getUsername());
        playlistWebSocketService.removeTrack(playlistId, userId, message);
    }

    @MessageMapping("/playlist/{playlistId}/move")
    public void moveTrack(
            @DestinationVariable UUID playlistId,
            @Payload MoveTrackMessage message,
            @AuthenticationPrincipal UserDetails userDetails) {

        UUID userId = UUID.fromString(userDetails.getUsername());
        playlistWebSocketService.moveTrack(playlistId, userId, message);
    }
}