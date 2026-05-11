package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.websocket.VoteMessage;
import com.musicroom.musicroom.dto.websocket.VoteUpdateMessage;
import java.util.UUID;

public interface VoteWebSocketService {
    VoteUpdateMessage vote(UUID eventId, UUID userId, VoteMessage message);
}