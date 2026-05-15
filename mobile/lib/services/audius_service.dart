import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/playlist_model.dart';
import '../models/track_model.dart';

class AudiusService {
  // Use the standard Audius API redirector
  static const String baseUrl = 'https://api.audius.co/v1';

  Future<List<Playlist>> getTrendingPlaylists() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/playlists/trending?limit=6'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> playlistsJson = data['data'] ?? [];
        return playlistsJson.map((json) => Playlist.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Audius Error (playlists): $e');
      return [];
    }
  }

  Future<List<Track>> getTrendingTracks() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/tracks/trending?limit=10'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tracksJson = data['data'] ?? [];
        return tracksJson.map((json) => Track.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Audius Error (tracks): $e');
      return [];
    }
  }

  // Example of using the requested endpoint, although for counting transactions
  // Get a specific playlist by ID
  Future<Playlist?> getPlaylist(String playlistId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/playlists/$playlistId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlistJson = data['data'];
        if (playlistJson != null &&
            playlistJson is List &&
            playlistJson.isNotEmpty) {
          return Playlist.fromJson(playlistJson[0]);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching playlist $playlistId: $e');
      return null;
    }
  }

  Future<int> getUsdcTransactionCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/transactions/usdc/count'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching USDC transaction count: $e');
      return 0;
    }
  }

  Future<List<Track>> searchTracks(String query) async {
    try {
      // Encode query for URL safety
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http
          .get(Uri.parse('$baseUrl/tracks/search?query=$encodedQuery'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tracksJson = data['data'] ?? [];
        return tracksJson.map((json) => Track.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Audius Error (search): $e');
      return [];
    }
  }

  /// Fetches track data from Audius (videos aren't a distinct type, but we can fetch trending)
  Future<List<Track>> getMusicVideos() async {
    try {
      // Audius doesn't have a specific "videos" endpoint for trending,
      // but we can fetch high-quality trending tracks as a substitute
      final response = await http
          .get(Uri.parse('$baseUrl/tracks/trending?limit=5'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tracksJson = data['data'] ?? [];
        return tracksJson.map((json) => Track.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Audius Error (videos): $e');
      return [];
    }
  }
}
