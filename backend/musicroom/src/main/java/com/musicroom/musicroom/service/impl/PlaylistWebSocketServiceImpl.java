package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.PlaylistEntryDto;
import com.musicroom.musicroom.dto.websocket.*;
import com.musicroom.musicroom.entity.*;
import com.musicroom.musicroom.exception.ConflictException;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.repository.*;
import com.musicroom.musicroom.service.PlaylistWebSocketService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PlaylistWebSocketServiceImpl implements PlaylistWebSocketService {

    private final PlaylistRepository playlistRepo;
    private final PlaylistTrackRepository playlistTrackRepo;
    private final PlaylistOperationRepository operationRepo;
    private final TrackRepository trackRepo;
    private final SimpMessagingTemplate messagingTemplate;
    private final PlaylistInviteRepository inviteRepo;

    private void checkEditPermission(Playlist playlist, UUID userId) {
        if (playlist.getOwner().getId().equals(userId)) {
            return;
        }

        boolean isEditor = inviteRepo.findByPlaylistIdAndUserId(playlist.getId(), userId)
                .map(invite -> "editor".equalsIgnoreCase(invite.getPermission()))
                .orElse(false);

        if (!isEditor) {
            throw new org.springframework.security.access.AccessDeniedException("Not authorized to edit this playlist");
        }
    }

    @Override
    @Transactional
    public PlaylistUpdateMessage addTrack(UUID playlistId, UUID userId, AddTrackMessage message) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        checkEditPermission(playlist, userId);

        // vérifier la version pour détecter les conflits
        if (!message.getVersion().equals(playlist.getVersion())) {
            PlaylistUpdateMessage conflict = buildConflictMessage(playlist, userId);
            broadcast(playlistId, conflict);
            return conflict;
        }

        // chercher ou créer la track
        Track track = trackRepo
                .findByExternalIdAndProvider(message.getExternalId(), message.getProvider())
                .orElseGet(() -> trackRepo.save(Track.builder()
                        .externalId(message.getExternalId())
                        .provider(message.getProvider())
                        .title(message.getTitle())
                        .artist(message.getArtist())
                        .album(message.getAlbum())
                        .coverUrl(message.getCoverUrl())
                        .durationMs(message.getDurationMs())
                        .build()));

        // vérifier si la track est déjà dans la playlist
        if (playlistTrackRepo.existsByPlaylistIdAndTrackId(playlistId, track.getId())) {
            throw new ConflictException("Track already in playlist");
        }

        // ajouter la track
        int nextPosition = playlistTrackRepo.countByPlaylistId(playlistId);
        PlaylistTrack playlistTrack = PlaylistTrack.builder()
                .playlist(playlist)
                .track(track)
                .addedBy(userId)
                .position(nextPosition)
                .build();

        playlistTrackRepo.save(playlistTrack);

        // incrémenter la version
        playlist.setVersion(playlist.getVersion() + 1);
        playlistRepo.save(playlist);

        // enregistrer l'opération
        saveOperation(playlist, userId, "add",
                Map.of("trackId", track.getId().toString()));

        // construire le message
        PlaylistUpdateMessage updateMessage = PlaylistUpdateMessage.builder()
                .type(PlaylistMessageType.TRACK_ADDED)
                .playlistId(playlistId)
                .version(playlist.getVersion())
                .userId(userId)
                .track(toEntryDto(playlistTrack))
                .build();

        // broadcaster à tous les clients
        broadcast(playlistId, updateMessage);
        return updateMessage;
    }

    @Override
    @Transactional
    public PlaylistUpdateMessage removeTrack(UUID playlistId, UUID userId, RemoveTrackMessage message) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        checkEditPermission(playlist, userId);

        // vérifier la version
        if (!message.getVersion().equals(playlist.getVersion())) {
            PlaylistUpdateMessage conflict = buildConflictMessage(playlist, userId);
            broadcast(playlistId, conflict);
            return conflict;
        }

        PlaylistTrack playlistTrack = playlistTrackRepo
                .findById(message.getTrackId())
                .filter(pt -> pt.getPlaylist().getId().equals(playlistId))
                .orElseThrow(() -> new ResourceNotFoundException("Track not in playlist"));

        playlistTrackRepo.delete(playlistTrack);

        // recalculer les positions
        List<PlaylistTrack> remaining = playlistTrackRepo
                .findByPlaylistIdOrderByPosition(playlistId);
        for (int i = 0; i < remaining.size(); i++) {
            remaining.get(i).setPosition(i);
        }
        playlistTrackRepo.saveAll(remaining);

        // incrémenter la version
        playlist.setVersion(playlist.getVersion() + 1);
        playlistRepo.save(playlist);

        // enregistrer l'opération
        saveOperation(playlist, userId, "remove",
                Map.of("trackId", message.getTrackId().toString()));

        // construire le message
        PlaylistUpdateMessage updateMessage = PlaylistUpdateMessage.builder()
                .type(PlaylistMessageType.TRACK_REMOVED)
                .playlistId(playlistId)
                .version(playlist.getVersion())
                .userId(userId)
                .track(PlaylistEntryDto.builder()
                        .id(message.getTrackId())
                        .build())
                .build();

        broadcast(playlistId, updateMessage);
        return updateMessage;
    }

    @Override
    @Transactional
    public PlaylistUpdateMessage moveTrack(UUID playlistId, UUID userId, MoveTrackMessage message) {
        Playlist playlist = playlistRepo.findById(playlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Playlist not found"));

        // vérifier la version
        if (!message.getVersion().equals(playlist.getVersion())) {
            PlaylistUpdateMessage conflict = buildConflictMessage(playlist, userId);
            broadcast(playlistId, conflict);
            return conflict;
        }

        PlaylistTrack trackToMove = playlistTrackRepo
                .findById(message.getTrackId())
                .filter(pt -> pt.getPlaylist().getId().equals(playlistId))
                .orElseThrow(() -> new ResourceNotFoundException("Track not in playlist"));

        List<PlaylistTrack> allTracks = playlistTrackRepo
                .findByPlaylistIdOrderByPosition(playlistId);

        // recalculer les positions
        allTracks.remove(trackToMove);
        allTracks.add(message.getNewPosition(), trackToMove);
        for (int i = 0; i < allTracks.size(); i++) {
            allTracks.get(i).setPosition(i);
        }
        playlistTrackRepo.saveAll(allTracks);

        // incrémenter la version
        playlist.setVersion(playlist.getVersion() + 1);
        playlistRepo.save(playlist);

        // enregistrer l'opération
        saveOperation(playlist, userId, "move",
                Map.of(
                    "trackId", message.getTrackId().toString(),
                    "newPosition", message.getNewPosition().toString()
                ));

        // construire le message
        PlaylistUpdateMessage updateMessage = PlaylistUpdateMessage.builder()
                .type(PlaylistMessageType.TRACK_MOVED)
                .playlistId(playlistId)
                .version(playlist.getVersion())
                .userId(userId)
                .tracks(allTracks.stream()
                        .map(this::toEntryDto)
                        .collect(Collectors.toList()))
                .build();

        broadcast(playlistId, updateMessage);
        return updateMessage;
    }

    // envoyer le message à tous les clients abonnés
    private void broadcast(UUID playlistId, PlaylistUpdateMessage message) {
        messagingTemplate.convertAndSend(
                "/topic/playlist/" + playlistId,
                message
        );
    }

    // construire un message de conflit avec la playlist complète
    private PlaylistUpdateMessage buildConflictMessage(Playlist playlist, UUID userId) {
        List<PlaylistEntryDto> currentTracks = playlistTrackRepo
                .findByPlaylistIdOrderByPosition(playlist.getId())
                .stream()
                .map(this::toEntryDto)
                .collect(Collectors.toList());

        return PlaylistUpdateMessage.builder()
                .type(PlaylistMessageType.CONFLICT)
                .playlistId(playlist.getId())
                .version(playlist.getVersion())
                .userId(userId)
                .message("Version conflict - reload playlist")
                .tracks(currentTracks)
                .build();
    }

    // enregistrer l'opération dans la table playlist_operations
    private void saveOperation(Playlist playlist, UUID userId,
                               String operation, Map<String, Object> payload) {
        PlaylistOperation op = new PlaylistOperation();
        op.setPlaylist(playlist);
        op.setUserId(userId);
        op.setOperation(operation);
        op.setPayload(payload);
        op.setVersion(playlist.getVersion());
        operationRepo.save(op);
    }

    // mapper PlaylistTrack vers PlaylistEntryDto
    private PlaylistEntryDto toEntryDto(PlaylistTrack pt) {
        return PlaylistEntryDto.builder()
                .id(pt.getId())
                .title(pt.getTrack().getTitle())
                .artist(pt.getTrack().getArtist())
                .coverUrl(pt.getTrack().getCoverUrl())
                .durationMs(pt.getTrack().getDurationMs())
                .position(pt.getPosition())
                .externalId(pt.getTrack().getExternalId())
                .build();
    }
}