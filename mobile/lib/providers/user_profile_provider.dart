import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';

class UserProfileProvider with ChangeNotifier {
  final UserService _userService = UserService();
  
  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _userService.getCurrentUserProfile(token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
