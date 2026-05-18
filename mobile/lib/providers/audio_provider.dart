import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track_model.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Track> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _isPlayerMaximized = false;

  AudioProvider() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        nextTrack();
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
  }

  Track? get currentTrack => (_currentIndex >= 0 && _currentIndex < _playlist.length) 
        ? _playlist[_currentIndex] 
        : null;
        
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlayerMaximized => _isPlayerMaximized;
  bool get hasTrack => currentTrack != null;

  void maximizePlayer() {
    _isPlayerMaximized = true;
    notifyListeners();
  }

  void minimizePlayer() {
    _isPlayerMaximized = false;
    notifyListeners();
  }

  Future<void> playTrack(Track track, {List<Track>? playlist, int index = 0}) async {
    if (playlist != null) {
      _playlist = playlist;
      _currentIndex = index;
    } else {
      _playlist = [track];
      _currentIndex = 0;
    }

    debugPrint("--- AudioProvider.playTrack: playing track id: ${track.id}, title: ${track.title}, URL: ${track.audioUrl}");

    if (track.audioUrl != null && track.audioUrl!.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(track.audioUrl!);
        _audioPlayer.play();
      } catch (e) {
        debugPrint("Error playing audio: \$e");
      }
    } else {
      debugPrint("--- AudioProvider.playTrack: ERROR: track.audioUrl is empty or null!");
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _playlist = [];
      _currentIndex = -1;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint("Error stopping audio: \$e");
    }
  }

  Future<void> nextTrack() async {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      if (_playlist[_currentIndex].audioUrl != null && _playlist[_currentIndex].audioUrl!.isNotEmpty) {
        try {
          await _audioPlayer.setUrl(_playlist[_currentIndex].audioUrl!);
          _audioPlayer.play();
        } catch (e) {
          debugPrint("Error playing next audio: \$e");
          // Optionally, automatically skip to the next track if this one fails
          // nextTrack();
        }
      }
      notifyListeners();
    }
  }

  Future<void> previousTrack() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      if (_playlist[_currentIndex].audioUrl != null && _playlist[_currentIndex].audioUrl!.isNotEmpty) {
        try {
          await _audioPlayer.setUrl(_playlist[_currentIndex].audioUrl!);
          _audioPlayer.play();
        } catch (e) {
          debugPrint("Error playing previous audio: \$e");
          // Optionally, automatically skip to the previous track if this one fails
          // previousTrack();
        }
      }
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
