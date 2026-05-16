import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/playlist_model.dart';
import '../../models/track_model.dart';
import '../../services/audius_service.dart';
import '../../services/playlist_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/audio_provider.dart';
import '../../config/app_theme.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final Playlist? initialPlaylist;
  final bool useBackend;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.initialPlaylist,
    this.useBackend = false,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  Playlist? _playlist;
  List<Track> _tracks = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _didRetryAfterOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchPlaylist();
  }

  Future<void> _fetchPlaylist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.useBackend) {
        final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.accessToken;
        if (token == null || token.isEmpty) {
          throw Exception('Missing auth token');
        }

        final playlistService = PlaylistService();
        var tracks = await playlistService.getPlaylistTracks(widget.playlistId, token);
        if (tracks.isEmpty && !_didRetryAfterOpen) {
          _didRetryAfterOpen = true;
          await Future.delayed(const Duration(milliseconds: 700));
          tracks = await playlistService.getPlaylistTracks(widget.playlistId, token);
        }
        if (!mounted) return;
        setState(() {
          _playlist = widget.initialPlaylist;
          _tracks = tracks;
          _isLoading = false;
        });
        return;
      }

      final audiusService = AudiusService();
      final playlist = await audiusService.getPlaylist(widget.playlistId);
      if (!mounted) return;
      setState(() {
        _playlist = playlist;
        _tracks = [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          : _playlist == null
          ? const Center(
              child: Text(
                'Playlist not found',
                style: TextStyle(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Playlist Artwork
                  if (_playlist!.imageUrl != null)
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.network(
                          _playlist!.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Playlist Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _playlist!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By ${_playlist!.creatorName}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.useBackend)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tracks (${_tracks.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (widget.useBackend) const SizedBox(height: 10),
                  if (widget.useBackend && _tracks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'No tracks in this playlist yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  if (widget.useBackend && _tracks.isNotEmpty)
                    ..._tracks.asMap().entries.map(
                      (entry) => _buildTrackTile(entry.key, entry.value),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildTrackTile(int index, Track track) {
    return ListTile(
      leading: SizedBox(
        width: 38,
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white60),
        ),
      ),
      title: Text(
        track.title,
        style: const TextStyle(color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artistName,
        style: const TextStyle(color: Colors.white60),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.music_note_rounded, color: Colors.white54),
      onTap: track.audioUrl == null
          ? null
          : () {
              Provider.of<AudioProvider>(context, listen: false).playTrack(
                track,
                playlist: _tracks,
                index: index,
              );
            },
    );
  }
}
