import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';

class UserProfileProvider with ChangeNotifier {
  final UserService _userService = UserService();

  UserProfileModel? _profile;
  List<Map<String, dynamic>> _userEvents = [];
  int _friendsCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileModel? get profile => _profile;
  List<Map<String, dynamic>> get userEvents => _userEvents;
  int get playlistsCount => _userEvents.length;
  int get friendsCount => _friendsCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _userService.getCurrentUserProfile(token);
      if (_profile != null && _profile!.id.isNotEmpty) {
        // Fetch additional stats in parallel
        final results = await Future.wait([
          _userService.getUserEvents(token, _profile!.id),
          _userService.getUserFriendsCount(token),
        ]);
        _userEvents = results[0] as List<Map<String, dynamic>>;
        _friendsCount = results[1] as int;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(
    String token,
    String newDisplayName,
    String? newAvatarUrl, {
    Map<String, dynamic>? publicInfo,
    Map<String, dynamic>? privateInfo,
    Map<String, dynamic>? friendsInfo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{
        'displayName': newDisplayName,
        if (newAvatarUrl != null && newAvatarUrl.isNotEmpty)
          'avatarUrl': newAvatarUrl,
        if (publicInfo != null) 'publicInfo': publicInfo,
        if (privateInfo != null) 'privateInfo': privateInfo,
        if (friendsInfo != null) 'friendsInfo': friendsInfo,
      };

      final updatedProfile = await _userService.updateUserProfile(
        token,
        updateData,
      );
      _profile = updatedProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePreferences(
    String token,
    Map<String, dynamic> newPreferences,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _userService.updateUserPreferences(
        token,
        newPreferences,
      );
      _profile = updatedProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
