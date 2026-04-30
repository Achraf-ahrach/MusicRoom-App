package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.dto.CreateTrackRequest;
import com.musicroom.musicroom.dto.TrackDto;
import com.musicroom.musicroom.entity.Track;
import com.musicroom.musicroom.exception.ConflictException;
import com.musicroom.musicroom.exception.ResourceNotFoundException;
import com.musicroom.musicroom.repository.TrackRepository;
import com.musicroom.musicroom.service.TrackService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TrackServiceImpl implements TrackService {

    private final TrackRepository trackRepo;

    @Override
    @Transactional
    public TrackDto createTrack(CreateTrackRequest request) {

        // vérifier si la track existe déjà
        trackRepo.findByExternalIdAndProvider(
                request.getExternalId(),
                request.getProvider())
                .ifPresent(t -> {
                    throw new ConflictException("Track already exists");
                });

        Track track = Track.builder()
                .externalId(request.getExternalId())
                .provider(request.getProvider())
                .title(request.getTitle())
                .artist(request.getArtist())
                .album(request.getAlbum())
                .coverUrl(request.getCoverUrl())
                .durationMs(request.getDurationMs())
                .build();

        trackRepo.save(track);
        return toDto(track);
    }

    @Override
    public TrackDto getTrackById(UUID trackId) {
        Track track = trackRepo.findById(trackId)
                .orElseThrow(() -> new ResourceNotFoundException("Track not found"));
        return toDto(track);
    }

    @Override
    public List<TrackDto> searchByTitle(String title) {
        return trackRepo.findByTitleContainingIgnoreCase(title)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    public List<TrackDto> searchByArtist(String artist) {
        return trackRepo.findByArtistContainingIgnoreCase(artist)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    public List<TrackDto> getByProvider(String provider) {
        return trackRepo.findByProvider(provider)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void deleteTrack(UUID trackId) {
        Track track = trackRepo.findById(trackId)
                .orElseThrow(() -> new ResourceNotFoundException("Track not found"));
        trackRepo.delete(track);
    }

    // mapper Track → TrackDto
    private TrackDto toDto(Track track) {
        return TrackDto.builder()
                .id(track.getId())
                .externalId(track.getExternalId())
                .provider(track.getProvider())
                .title(track.getTitle())
                .artist(track.getArtist())
                .album(track.getAlbum())
                .coverUrl(track.getCoverUrl())
                .durationMs(track.getDurationMs())
                .build();
    }
}