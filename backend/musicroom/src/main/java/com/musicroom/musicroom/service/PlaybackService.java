package com.musicroom.musicroom.service;

import java.util.UUID;

/**
 * Manages server-side playback state for events.
 * Once an event is started, playback runs autonomously:
 * - The first track plays immediately
 * - When a track ends (based on duration), it is removed and the next track auto-plays
 * - Playback cannot be paused or stopped by anyone
 * - All listeners receive synchronized PLAY commands via WebSocket
 */
public interface PlaybackService {

    /**
     * Start the event playback. Plays the first track in the queue
     * and schedules auto-advance when it finishes.
     */
    void startEvent(UUID eventId, UUID userId);

    /**
     * Check if an event is currently playing.
     */
    boolean isEventPlaying(UUID eventId);

    /**
     * Called when the playlist changes (track added/removed/reordered)
     * to potentially start playback if the event is playing but has no current track.
     */
    void onPlaylistChanged(UUID eventId);

    /**
     * Stop tracking playback for an event (when event is deleted).
     */
    void stopEvent(UUID eventId);

    /**
     * Skip the currently playing track and advance to the next track.
     */
    void skipTrack(UUID eventId, UUID userId);

    /**
     * Get rich playback status including isPlaying and positionMs.
     */
    java.util.Map<String, Object> getPlaybackStatus(UUID eventId);
}
