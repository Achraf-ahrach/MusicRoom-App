import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/playlist_model.dart';
import '../../models/track_model.dart';
import '../../services/audius_service.dart';
import '../../services/playlist_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/audio_player_overlay.dart';
import 'package:musicroom/screens/user_public_profile_screen.dart';


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
  bool _isSaved = false;

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
        final freshPlaylist = await playlistService.getPlaylistById(widget.playlistId, token);
        var tracks = await playlistService.getPlaylistTracks(widget.playlistId, token);
        if (tracks.isEmpty && !_didRetryAfterOpen) {
          _didRetryAfterOpen = true;
          await Future.delayed(const Duration(milliseconds: 700));
          tracks = await playlistService.getPlaylistTracks(widget.playlistId, token);
        }
        
        bool isSaved = false;
        try {
          isSaved = await playlistService.isPlaylistSaved(widget.playlistId, token);
        } catch (e) {
          debugPrint('Error fetching status: $e');
        }

        if (!mounted) return;
        setState(() {
          _playlist = freshPlaylist;
          _tracks = tracks;
          _isSaved = isSaved;
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

  Future<void> _toggleSave() async {
    final token = Provider.of<AuthProvider>(context, listen: false).currentUser?.accessToken;
    if (token == null) return;
    final playlistService = PlaylistService();
    try {
      if (_isSaved) {
        await playlistService.unsavePlaylist(widget.playlistId, token);
      } else {
        await playlistService.savePlaylist(widget.playlistId, token);
      }
      setState(() {
        _isSaved = !_isSaved;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update save status: $e')),
      );
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
        actions: [
          if (widget.useBackend && _playlist != null)
            Builder(
              builder: (context) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final isOwner = _playlist!.ownerId == auth.currentUser?.id;
                if (!isOwner) return const SizedBox.shrink();

                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: AppTheme.surface,
                  onSelected: (value) async {
                    if (value == 'toggle_visibility') {
                      final newVisibility = _playlist!.visibility == 'private' ? 'public' : 'private';
                      final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
                      try {
                        setState(() {
                          _isLoading = true;
                        });
                        final updated = await playlistProvider.updatePlaylistVisibility(
                          _playlist!,
                          newVisibility,
                          auth.currentUser,
                        );
                        setState(() {
                          _playlist = updated;
                          _isLoading = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Playlist is now $newVisibility!'),
                              backgroundColor: AppTheme.accent,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update: $e')),
                          );
                        }
                      }
                    } else if (value == 'delete_playlist') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.surface,
                          title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
                          content: const Text('Are you sure you want to delete this playlist? This cannot be undone.', style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        setState(() => _isLoading = true);
                        try {
                          final playlistService = PlaylistService();
                          await playlistService.deletePlaylist(widget.playlistId, auth.currentUser!.accessToken);
                          
                          if (mounted) {
                            final provider = Provider.of<PlaylistProvider>(context, listen: false);
                            provider.removePlaylistLocal(widget.playlistId);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Playlist deleted successfully'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            Navigator.pop(context, true); // Pop back to library/home
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'toggle_visibility',
                      child: Row(
                        children: [
                          Icon(
                            _playlist!.visibility == 'private'
                                ? Icons.public_rounded
                                : Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _playlist!.visibility == 'private'
                                ? 'Make Public'
                                : 'Make Private',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem<String>(
                      value: 'delete_playlist',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Delete Playlist',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
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
                      Builder(
                        builder: (context) {
                          final String? displayCoverUrl = (_playlist!.imageUrl != null && _playlist!.imageUrl!.isNotEmpty)
                              ? _playlist!.imageUrl
                              : (_tracks.isNotEmpty && _tracks.first.imageUrl != null && _tracks.first.imageUrl!.isNotEmpty)
                                  ? _tracks.first.imageUrl
                                  : null;

                          if (displayCoverUrl != null) {
                            return Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  displayCoverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.music_note, color: Colors.grey, size: 80),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[900],
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white24,
                                  size: 80,
                                ),
                              ),
                            );
                          }
                        },
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
                             Row(
                              children: [
                                GestureDetector(
                                  onTap: widget.useBackend && _playlist!.ownerId.isNotEmpty
                                      ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UserPublicProfileScreen(
                                              userId: _playlist!.ownerId,
                                              displayName: _playlist!.creatorName,
                                            ),
                                          ),
                                        )
                                      : null,
                                  child: Text(
                                    'By ${_playlist!.creatorName}',
                                    style: TextStyle(
                                      color: widget.useBackend
                                          ? AppTheme.accent
                                          : Colors.white.withValues(alpha: 0.7),
                                      fontSize: 16,
                                      decoration: widget.useBackend
                                          ? TextDecoration.underline
                                          : null,
                                      decorationColor: AppTheme.accent,
                                    ),
                                  ),
                                ),
                                if (widget.useBackend) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _playlist!.visibility == 'private'
                                          ? Colors.redAccent.withValues(alpha: 0.15)
                                          : AppTheme.accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _playlist!.visibility == 'private'
                                            ? Colors.redAccent
                                            : AppTheme.accent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _playlist!.visibility == 'private'
                                              ? Icons.lock_outline_rounded
                                              : Icons.public_rounded,
                                          size: 11,
                                          color: _playlist!.visibility == 'private'
                                              ? Colors.redAccent
                                              : AppTheme.accent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _playlist!.visibility == 'private' ? 'Private' : 'Public',
                                          style: TextStyle(
                                            color: _playlist!.visibility == 'private'
                                                ? Colors.redAccent
                                                : AppTheme.accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.useBackend)
                        Builder(
                          builder: (context) {
                            final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
                            final isOwner = currentUser?.id == _playlist!.ownerId;
                            if (isOwner) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: OutlinedButton.icon(
                                onPressed: _toggleSave,
                                icon: Icon(
                                  _isSaved ? Icons.remove_circle_outline : Icons.add,
                                  color: _isSaved ? Colors.redAccent : Colors.white,
                                  size: 18,
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _isSaved ? Colors.redAccent : Colors.white,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                label: Text(
                                  _isSaved ? 'Remove Playlist' : 'Save Playlist',
                                  style: TextStyle(
                                    color: _isSaved ? Colors.redAccent : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }
                        ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
          const AudioPlayerOverlay(),
        ],
      ),
    );
  }

  Widget _buildTrackTile(int index, Track track) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 25,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: track.imageUrl != null && track.imageUrl!.isNotEmpty
                ? Image.network(
                    track.imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.music_note, color: Colors.grey, size: 20),
                    ),
                  )
                : Container(
                    color: Colors.grey[900],
                    width: 44,
                    height: 44,
                    child: const Icon(Icons.music_note, color: Colors.grey, size: 20),
                  ),
          ),
        ],
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
      trailing: Builder(
        builder: (context) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final isOwner = _playlist?.ownerId == auth.currentUser?.id;

          if (widget.useBackend && isOwner && track.playlistTrackId != null) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: AppTheme.surface,
              onSelected: (value) async {
                if (value == 'remove_track') {
                  try {
                    setState(() => _isLoading = true);
                    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
                    await playlistProvider.removeTrackFromPlaylist(
                      _playlist!,
                      track.playlistTrackId!,
                      auth.currentUser,
                    );
                    
                    setState(() {
                      _tracks.removeAt(index);
                      _isLoading = false;
                    });
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Track removed successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to remove track: $e')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'remove_track',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text('Remove Track', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Icon(Icons.music_note_rounded, color: Colors.white54);
        }
      ),
      onTap: track.audioUrl == null
          ? null
          : () {
              final audioProvider = Provider.of<AudioProvider>(context, listen: false);
              audioProvider.playTrack(
                track,
                playlist: _tracks,
                index: index,
              );
            },
    );
  }
}
