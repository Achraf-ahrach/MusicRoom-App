import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import 'add_to_playlist_modal.dart';

class AudioPlayerOverlay extends StatelessWidget {
  const AudioPlayerOverlay({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.hasTrack) return const SizedBox.shrink();

        final track = audioProvider.currentTrack!;

        if (audioProvider.isPlayerMaximized) {
          return GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 300) {
                audioProvider.minimizePlayer();
              }
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -300) {
                audioProvider.nextTrack();
              } else if (velocity > 300) {
                audioProvider.previousTrack();
              }
            },
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () => audioProvider.minimizePlayer(),
                        ),
                        const Text(
                          "Now Playing",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  AddToPlaylistModal(track: track),
                            );
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Center(
                              child: track.imageUrl != null
                                  ? Image.network(
                                      track.imageUrl!,
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.8,
                                      height:
                                          MediaQuery.of(context).size.width *
                                          0.8,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.8,
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.8,
                                                color: Colors.grey[800],
                                                child: const Icon(
                                                  Icons.music_note,
                                                  color: Colors.grey,
                                                  size: 100,
                                                ),
                                              ),
                                    )
                                  : Container(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.8,
                                      height:
                                          MediaQuery.of(context).size.width *
                                          0.8,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.grey,
                                        size: 100,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              track.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              track.artistName,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    // Bottom controls area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Slider(
                            activeColor: Colors.white,
                            inactiveColor: Colors.grey.withOpacity(0.5),
                            value: audioProvider.position.inSeconds
                                .toDouble()
                                .clamp(
                                  0.0,
                                  audioProvider.duration.inSeconds.toDouble() >
                                          0
                                      ? audioProvider.duration.inSeconds
                                            .toDouble()
                                      : 1.0,
                                ),
                            max: audioProvider.duration.inSeconds.toDouble() > 0
                                ? audioProvider.duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: audioProvider.isLiveEvent
                                ? null
                                : (val) {
                                    audioProvider.seek(
                                      Duration(seconds: val.toInt()),
                                    );
                                  },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(audioProvider.position),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDuration(audioProvider.duration),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (audioProvider.isLiveEvent) ...[
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: audioProvider.onSyncPlayback,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.greenAccent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.sync_rounded,
                                      color: Colors.greenAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "LIVE - TAP TO SYNC",
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  iconSize: 48,
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      audioProvider.previousTrack(),
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  iconSize: 64,
                                  icon: Icon(
                                    audioProvider.isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      audioProvider.togglePlayPause(),
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  iconSize: 48,
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => audioProvider.nextTrack(),
                                ),
                              ],
                            ),
                          ],
                          if (track.description != null &&
                              track.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Description",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    track.description!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Mini player
        return Positioned(
          bottom: 0,
          left: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => audioProvider.maximizePlayer(),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  if (track.imageUrl != null)
                    Image.network(
                      track.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          track.artistName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (audioProvider.isLiveEvent)
                    GestureDetector(
                      onTap: audioProvider.onSyncPlayback,
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync_rounded,
                              color: Colors.greenAccent,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "SYNC",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            audioProvider.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () => audioProvider.togglePlayPause(),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                          ),
                          onPressed: () => audioProvider.nextTrack(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
