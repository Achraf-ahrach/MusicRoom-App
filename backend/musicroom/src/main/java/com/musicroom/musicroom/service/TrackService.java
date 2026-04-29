package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.CreateTrackRequest;
import com.musicroom.musicroom.dto.TrackDto;
import java.util.List;
import java.util.UUID;

public interface TrackService {
    TrackDto createTrack(CreateTrackRequest request);
    TrackDto getTrackById(UUID trackId);
    List<TrackDto> searchByTitle(String title);
    List<TrackDto> searchByArtist(String artist);
    List<TrackDto> getByProvider(String provider);
    void deleteTrack(UUID trackId);
}