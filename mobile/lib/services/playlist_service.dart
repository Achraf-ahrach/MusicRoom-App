import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';

class PlaylistService {
  String get _effectiveBaseUrl => 'https://anisa-phenetic-predictively.ngrok-free.dev';

  StompClient? _stompClient;
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'User-Agent': 'MusicRoomApp/1.0',
        'ngrok-skip-browser-warning': 'true',
      };

  // Retrieve current playlists
  Future<List<Playlist>> getMyPlaylists(String token) async {
    final response = await http.get(
      Uri.parse('$_effectiveBaseUrl/api/playlists'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Playlist.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load playlists (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
      );
    }
  }

  Future<List<Track>> getPlaylistTracks(String playlistId, String token) async {
    final response = await http.get(
      Uri.parse('$_effectiveBaseUrl/api/playlists/$playlistId/tracks'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data
          .map((json) => Track.fromPlaylistTrackJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'Failed to load playlist tracks (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
    );
  }

  // Create a new playlist
  Future<Playlist> createPlaylist(String name, String description, String visibility, String token) async {
    final response = await http.post(
      Uri.parse('$_effectiveBaseUrl/api/playlists'),
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        'description': description,
        'visibility': visibility,
        'licenseType': 'open',
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Playlist.fromJson(data);
    } else {
      throw Exception(
        'Failed to create playlist (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
      );
    }
  }

  // Add track to playlist using WebSockets
  Future<void> addTrackToPlaylist(String playlistId, Track track, String token, int version) async {
    final completer = Completer<void>();

    if (_stompClient != null && _stompClient!.isActive) {
      _sendAddTrackMessage(playlistId, track, token, version);
      completer.complete();
      return completer.future;
    }

    final wsUrl = _effectiveBaseUrl.replaceFirst('http', 'ws') + '/ws';
    
    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (StompFrame frame) {
          _sendAddTrackMessage(playlistId, track, token, version);
          if (!completer.isCompleted) {
            completer.complete();
          }
          
          // Disconnect after sending (or keep it open for other things)
          Future.delayed(const Duration(seconds: 2), () {
            _stompClient?.deactivate();
            _stompClient = null;
          });
        },
        onStompError: (frame) {
          if (!completer.isCompleted) {
            completer.completeError(
              Exception(frame.body ?? 'WebSocket STOMP error while adding track'),
            );
          }
        },
        onWebSocketError: (dynamic error) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('WebSocket error: $error'));
          }
        },
        onDisconnect: (frame) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('WebSocket disconnected before track add'));
          }
        },
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    _stompClient!.activate();
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception('Timed out while adding track to playlist'),
    );
  }

  void _sendAddTrackMessage(String playlistId, Track track, String token, int version) {
    if (_stompClient == null) return;
    
    _stompClient!.send(
      destination: '/app/playlist/$playlistId/add',
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'externalId': track.id,
        'provider': 'audius', // or fallback
        'title': track.title,
        'artist': track.artistName,
        'album': '',
        'coverUrl': track.imageUrl ?? '',
        'durationMs': null,
        'version': version,
      }),
    );
  }
}
