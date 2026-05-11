package com.musicroom.musicroom.dto.websocket;

import com.musicroom.musicroom.dto.PlaylistEntryDto;
import lombok.*;
import java.util.List;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class PlaylistUpdateMessage {

    // type de l'événement
    private PlaylistMessageType type;

    // id de la playlist concernée
    private UUID playlistId;

    // nouvelle version après la modification
    private Integer version;

    // id de l'utilisateur qui a fait l'action
    private UUID userId;

    // message d'erreur en cas de conflit
    private String message;

    // track concernée (pour TRACK_ADDED / TRACK_REMOVED / TRACK_MOVED)
    private PlaylistEntryDto track;

    // liste complète (pour PLAYLIST_RELOADED et CONFLICT)
    private List<PlaylistEntryDto> tracks;
}