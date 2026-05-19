package com.musicroom.musicroom.service;

import com.musicroom.musicroom.entity.Event;
import com.musicroom.musicroom.entity.User;
import com.musicroom.musicroom.exception.UnauthorizedException;
import com.musicroom.musicroom.repository.EventInviteRepository;
import com.musicroom.musicroom.repository.EventRepository;
import com.musicroom.musicroom.service.impl.EventServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.lang.reflect.Field;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EventPrivacyTests {

    @Mock
    private EventRepository eventRepo;

    @Mock
    private EventInviteRepository inviteRepo;

    @Mock
    private PlaybackService playbackService;

    @Mock
    private com.musicroom.musicroom.controller.WebSocketEventListener webSocketEventListener;

    private EventServiceImpl eventService;

    @BeforeEach
    void setUp() throws Exception {
        eventService = new EventServiceImpl(
            eventRepo,
            null,
            inviteRepo,
            null,
            null,
            null,
            null,
            playbackService
        );
        Field field = EventServiceImpl.class.getDeclaredField("webSocketEventListener");
        field.setAccessible(true);
        field.set(eventService, webSocketEventListener);
    }

    @Test
    void getEventById_whenPublic_shouldAllowAccess() {
        UUID userId = UUID.randomUUID();
        UUID eventId = UUID.randomUUID();

        User owner = new User();
        owner.setId(UUID.randomUUID());

        Event event = new Event();
        event.setId(eventId);
        event.setVisibility("public");
        event.setOwner(owner);

        when(eventRepo.findById(eventId)).thenReturn(Optional.of(event));

        assertNotNull(eventService.getEventById(userId, eventId));
    }

    @Test
    void getEventById_whenPrivateAndOwner_shouldAllowAccess() {
        UUID userId = UUID.randomUUID();
        UUID eventId = UUID.randomUUID();

        User owner = new User();
        owner.setId(userId);

        Event event = new Event();
        event.setId(eventId);
        event.setVisibility("private");
        event.setOwner(owner);

        when(eventRepo.findById(eventId)).thenReturn(Optional.of(event));

        assertNotNull(eventService.getEventById(userId, eventId));
    }

    @Test
    void getEventById_whenPrivateAndInvited_shouldAllowAccess() {
        UUID userId = UUID.randomUUID();
        UUID eventId = UUID.randomUUID();

        User owner = new User();
        owner.setId(UUID.randomUUID());

        Event event = new Event();
        event.setId(eventId);
        event.setVisibility("private");
        event.setOwner(owner);

        when(eventRepo.findById(eventId)).thenReturn(Optional.of(event));
        when(inviteRepo.existsByEventIdAndUserId(eventId, userId)).thenReturn(true);

        assertNotNull(eventService.getEventById(userId, eventId));
    }

    @Test
    void getEventById_whenPrivateAndNotInvited_shouldThrowUnauthorized() {
        UUID userId = UUID.randomUUID();
        UUID eventId = UUID.randomUUID();

        User owner = new User();
        owner.setId(UUID.randomUUID());

        Event event = new Event();
        event.setId(eventId);
        event.setVisibility("private");
        event.setOwner(owner);

        when(eventRepo.findById(eventId)).thenReturn(Optional.of(event));
        when(inviteRepo.existsByEventIdAndUserId(eventId, userId)).thenReturn(false);

        assertThrows(UnauthorizedException.class, () -> {
            eventService.getEventById(userId, eventId);
        });
    }
}
