package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.CreateTrackRequest;
import com.musicroom.musicroom.dto.TrackDto;
import com.musicroom.musicroom.service.TrackService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/tracks")
@RequiredArgsConstructor
@Tag(name = "Track", description = "Gestion du catalogue musical")
public class TrackController {

    private final TrackService trackService;

    @PostMapping
    public ResponseEntity<TrackDto> createTrack(
            @RequestBody CreateTrackRequest request) {
        return ResponseEntity.status(201).body(trackService.createTrack(request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TrackDto> getTrackById(
            @PathVariable UUID id) {
        return ResponseEntity.ok(trackService.getTrackById(id));
    }

    @GetMapping("/search/title")
    public ResponseEntity<List<TrackDto>> searchByTitle(
            @RequestParam String title) {
        return ResponseEntity.ok(trackService.searchByTitle(title));
    }

    @GetMapping("/search/artist")
    public ResponseEntity<List<TrackDto>> searchByArtist(
            @RequestParam String artist) {
        return ResponseEntity.ok(trackService.searchByArtist(artist));
    }

    @GetMapping("/provider/{provider}")
    public ResponseEntity<List<TrackDto>> getByProvider(
            @PathVariable String provider) {
        return ResponseEntity.ok(trackService.getByProvider(provider));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTrack(
            @PathVariable UUID id) {
        trackService.deleteTrack(id);
        return ResponseEntity.noContent().build();
    }
}