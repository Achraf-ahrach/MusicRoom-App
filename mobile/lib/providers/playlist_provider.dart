import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';
import '../models/user_model.dart';
import '../services/playlist_service.dart';
import 'auth_provider.dart';

class PlaylistProvider with ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  AuthProvider? _authProvider;

  List<Playlist> _playlists = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  UserModel? _resolveUser(UserModel? fallbackUser) {
    return _authProvider?.currentUser ?? fallbackUser;
  }

  Future<T> _withAuthRetry<T>(
    Future<T> Function(String token) action, {
    String? fallbackToken,
  }) async {
    final auth = _authProvider;
    var token = auth?.currentUser?.accessToken ?? fallbackToken ?? '';

    if (token.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      return await action(token);
    } catch (e) {
      final shouldRetry = e.toString().contains('401');
      if (shouldRetry && auth != null) {
        final refreshed = await auth.refreshTokens();
        if (refreshed) {
          token = auth.currentUser?.accessToken ?? '';
          if (token.isNotEmpty) {
            return await action(token);
          }
        }
      }
      rethrow;
    }
  }

  void _incrementPlaylistVersion(String playlistId) {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index == -1) return;

    final current = _playlists[index];
    _playlists[index] = Playlist(
      id: current.id,
      title: current.title,
      imageUrl: current.imageUrl,
      creatorName: current.creatorName,
      version: current.version + 1,
    );
  }

  Future<void> loadPlaylists(UserModel? user) async {
    final resolvedUser = _resolveUser(user);
    if (resolvedUser == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _playlists = await _withAuthRetry(
        (token) => _playlistService.getMyPlaylists(token),
        fallbackToken: resolvedUser.accessToken,
      );
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Failed to load playlists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Playlist> createPlaylist(String name, String description, String visibility, UserModel? user) async {
    final resolvedUser = _resolveUser(user);
    if (resolvedUser == null || resolvedUser.accessToken.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      Playlist newPlaylist = await _withAuthRetry(
        (token) => _playlistService.createPlaylist(name, description, visibility, token),
        fallbackToken: resolvedUser.accessToken,
      );
      _playlists = [newPlaylist, ..._playlists];
      _errorMessage = null;
      notifyListeners();
      return newPlaylist;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Failed to create playlist: $e');
      rethrow;
    }
  }

  Future<void> createPlaylistAndAddTrack(String name, String description, String visibility, Track track, UserModel? user) async {
    final resolvedUser = _resolveUser(user);
    if (resolvedUser == null || resolvedUser.accessToken.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      Playlist newPlaylist = await _withAuthRetry(
        (token) => _playlistService.createPlaylist(name, description, visibility, token),
        fallbackToken: resolvedUser.accessToken,
      );
      _playlists = [newPlaylist, ..._playlists];
      _errorMessage = null;
      notifyListeners();

      await _withAuthRetry(
        (token) => _playlistService.addTrackToPlaylist(
          newPlaylist.id,
          track,
          token,
          newPlaylist.version,
        ),
        fallbackToken: resolvedUser.accessToken,
      );
      _incrementPlaylistVersion(newPlaylist.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Failed to create playlist or add track: $e');
      rethrow;
    }
  }

  Future<void> addTrackToExistingPlaylist(Playlist playlist, Track track, UserModel? user) async {
    final resolvedUser = _resolveUser(user);
    if (resolvedUser == null || resolvedUser.accessToken.isEmpty) {
      throw Exception('User not authenticated');
    }
    await _withAuthRetry(
      (token) => _playlistService.addTrackToPlaylist(
        playlist.id,
        track,
        token,
        playlist.version,
      ),
      fallbackToken: resolvedUser.accessToken,
    );
    _errorMessage = null;
    _incrementPlaylistVersion(playlist.id);
    notifyListeners();
  }
}
