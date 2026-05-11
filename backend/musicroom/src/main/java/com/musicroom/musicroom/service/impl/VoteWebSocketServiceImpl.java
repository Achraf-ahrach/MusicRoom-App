package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.PlaylistEntryDto;
import com.musicroom.musicroom.dto.websocket.*;
import com.musicroom.musicroom.entity.*;
import com.musicroom.musicroom.exception.ConflictException;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.repository.*;
import com.musicroom.musicroom.service.VoteWebSocketService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class VoteWebSocketServiceImpl implements VoteWebSocketService {

    private final EventRepository eventRepo;
    private final EventPlaylistRepository playlistRepo;
    private final VoteRepository voteRepo;
    private final UserRepository userRepo;
    private final SimpMessagingTemplate messagingTemplate;

    @Override
    @Transactional
    public VoteUpdateMessage vote(UUID eventId, UUID userId, VoteMessage message) {

        // vérifier que l'event existe
        eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found"));

        // vérifier que la track existe dans l'event
        EventPlaylistEntry entry = playlistRepo.findById(message.getEntryId())
                .orElseThrow(() -> new ResourceNotFoundException("Track not found in event"));

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // vérifier si l'utilisateur a déjà voté
        Optional<Vote> existingVote = voteRepo
                .findByPlaylistEntryIdAndUserId(message.getEntryId(), userId);

        VoteUpdateMessage updateMessage;

        if (existingVote.isPresent()) {
            // l'utilisateur a déjà voté — changer son vote
            Vote vote = existingVote.get();
            int oldValue = vote.getValue();
            vote.setValue(message.getValue());
            voteRepo.save(vote);

            // mettre à jour le vote_count
            entry.setVoteCount(entry.getVoteCount() - oldValue + message.getValue());
            playlistRepo.save(entry);

            updateMessage = buildUpdateMessage(
                    VoteMessageType.VOTE_CHANGED,
                    eventId, userId, entry);

        } else {
            // nouveau vote
            Vote vote = Vote.builder()
                    .playlistEntry(entry)
                    .user(user)
                    .value(message.getValue())
                    .build();
            voteRepo.save(vote);

            entry.setVoteCount(entry.getVoteCount() + message.getValue());
            playlistRepo.save(entry);

            updateMessage = buildUpdateMessage(
                    VoteMessageType.VOTE_ADDED,
                    eventId, userId, entry);
        }

        // broadcaster à tous les clients de l'event
        broadcast(eventId, updateMessage);
        return updateMessage;
    }

    private VoteUpdateMessage buildUpdateMessage(
            VoteMessageType type,
            UUID eventId,
            UUID userId,
            EventPlaylistEntry entry) {

        // récupérer la playlist complète reordonnée par vote
        List<PlaylistEntryDto> playlist = playlistRepo
                .findByEventIdOrderByVoteCountDesc(eventId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());

        return VoteUpdateMessage.builder()
                .type(type)
                .eventId(eventId)
                .entryId(entry.getId())
                .userId(userId)
                .newVoteCount(entry.getVoteCount())
                .playlist(playlist)
                .build();
    }

    private void broadcast(UUID eventId, VoteUpdateMessage message) {
        messagingTemplate.convertAndSend(
                "/topic/event/" + eventId + "/playlist",
                message
        );
    }

    private PlaylistEntryDto toDto(EventPlaylistEntry entry) {
        return PlaylistEntryDto.builder()
                .id(entry.getId())
                .title(entry.getTrack().getTitle())
                .artist(entry.getTrack().getArtist())
                .coverUrl(entry.getTrack().getCoverUrl())
                .durationMs(entry.getTrack().getDurationMs())
                .voteCount(entry.getVoteCount())
                .position(entry.getPosition())
                .status(entry.getStatus())
                .suggestedById(entry.getSuggestedBy() != null ?
                        entry.getSuggestedBy().getId() : null)
                .suggestedByName(entry.getSuggestedBy() != null ?
                        entry.getSuggestedBy().getDisplayName() : null)
                .build();
    }
}