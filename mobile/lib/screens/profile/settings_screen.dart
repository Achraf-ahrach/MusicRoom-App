import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _genreOptions = const [
    'Pop',
    'Rock',
    'Hip Hop',
    'Jazz',
    'Electronic',
    'Indie',
    'R&B',
    'Classical',
  ];

  final List<String> _modeOptions = const ['active', 'passive'];

  bool _activeDiscovery = true;
  double _searchDistance = 50;
  bool _dataSaver = false;
  bool _offlineMode = false;
  bool _explicitContent = true;
  bool _privateSession = false;
  bool _notificationsEnabled = true;
  Set<String> _selectedGenres = {'Pop', 'Rock'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProfile());
  }

  void _loadFromProfile() {
    final profile = context.read<UserProfileProvider>().profile;
    final prefs = profile?.musicPreferences ?? {};

    setState(() {
      _activeDiscovery = prefs['discovery_mode']?.toString() != 'passive';
      _searchDistance =
          (prefs['max_distance_km'] as num?)?.toDouble() ?? _searchDistance;
      _dataSaver = prefs['data_saver'] as bool? ?? _dataSaver;
      _offlineMode = prefs['offline_mode'] as bool? ?? _offlineMode;
      _explicitContent = prefs['explicit_content'] as bool? ?? _explicitContent;
      _privateSession = prefs['private_session'] as bool? ?? _privateSession;
      _notificationsEnabled =
          prefs['notifications_enabled'] as bool? ?? _notificationsEnabled;

      final genres = prefs['favorite_genres'];
      if (genres is List) {
        _selectedGenres = genres.map((e) => e.toString()).toSet();
      }
    });
  }

  Future<void> _savePreferences() async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<UserProfileProvider>();
    final token = authProvider.currentUser?.accessToken;

    if (token == null) {
      return;
    }

    final success = await profileProvider.updatePreferences(token, {
      'discovery_mode': _activeDiscovery ? 'active' : 'passive',
      'max_distance_km': _searchDistance.round(),
      'favorite_genres': _selectedGenres.toList()..sort(),
      'data_saver': _dataSaver,
      'offline_mode': _offlineMode,
      'explicit_content': _explicitContent,
      'private_session': _privateSession,
      'notifications_enabled': _notificationsEnabled,
    });

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_mode', _offlineMode);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Settings saved' : 'Could not save settings'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _sectionTitle(String title, {String? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (action != null)
            Text(
              action,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
      trailing: trailing,
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _settingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(
        value: value,
        onChanged: (newValue) {
          setState(() => onChanged(newValue));
        },
        activeColor: const Color(0xFF1DB954),
      ),
    );
  }

  Widget _genreChip(String genre) {
    final isSelected = _selectedGenres.contains(genre);
    return FilterChip(
      selected: isSelected,
      label: Text(genre),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: const Color(0xFF1DB954),
      backgroundColor: Colors.white10,
      checkmarkColor: Colors.black,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedGenres.add(genre);
          } else {
            _selectedGenres.remove(genre);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final profile = profileProvider.profile;
    final isLoading = profileProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings & privacy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _savePreferences,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF1DB954),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _sectionTitle('Your profile'),
              _card(
                child: Column(
                  children: [
                    _settingTile(
                      icon: Icons.person,
                      title: profile?.displayName ?? 'My profile',
                      subtitle: profile?.email ?? 'Tap to edit account details',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    _settingTile(
                      icon: Icons.auto_awesome,
                      title: 'Discovery mode',
                      subtitle: _activeDiscovery ? 'Active' : 'Passive',
                      trailing: Switch.adaptive(
                        value: _activeDiscovery,
                        onChanged: (value) =>
                            setState(() => _activeDiscovery = value),
                        activeColor: const Color(0xFF1DB954),
                      ),
                    ),
                  ],
                ),
              ),
              _sectionTitle('Favorite genres'),
              _card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _genreOptions.map(_genreChip).toList(),
                  ),
                ),
              ),
              _sectionTitle('Listening'),
              _card(
                child: Column(
                  children: [
                    _settingTile(
                      icon: Icons.near_me,
                      title: 'Search distance',
                      subtitle: '${_searchDistance.round()} km',
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF1DB954),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: const Color(0xFF1DB954),
                        ),
                        child: Slider(
                          value: _searchDistance,
                          min: 10,
                          max: 250,
                          divisions: 24,
                          onChanged: (value) =>
                              setState(() => _searchDistance = value),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    _toggleTile(
                      icon: Icons.data_usage,
                      title: 'Data saver',
                      subtitle: 'Use less data for streaming and previews',
                      value: _dataSaver,
                      onChanged: (value) => _dataSaver = value,
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    _toggleTile(
                      icon: Icons.download,
                      title: 'Offline mode',
                      subtitle: 'Only play downloaded music when offline',
                      value: _offlineMode,
                      onChanged: (value) => _offlineMode = value,
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    _toggleTile(
                      icon: Icons.explicit,
                      title: 'Explicit content',
                      subtitle: 'Allow explicit songs in your recommendations',
                      value: _explicitContent,
                      onChanged: (value) => _explicitContent = value,
                    ),
                  ],
                ),
              ),
              _sectionTitle('Privacy & notifications'),
              _card(
                child: Column(
                  children: [
                    _toggleTile(
                      icon: Icons.visibility_off,
                      title: 'Private session',
                      subtitle:
                          'Keep listening activity hidden for this session',
                      value: _privateSession,
                      onChanged: (value) => _privateSession = value,
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    _toggleTile(
                      icon: Icons.notifications,
                      title: 'Push notifications',
                      subtitle:
                          'Get updates about playlists, follows, and events',
                      value: _notificationsEnabled,
                      onChanged: (value) => _notificationsEnabled = value,
                    ),
                  ],
                ),
              ),
              _sectionTitle('About'),
              _card(
                child: Column(
                  children: [
                    _settingTile(
                      icon: Icons.info_outline,
                      title: 'Version',
                      subtitle: '1.0.0',
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    _settingTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy policy',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    _settingTile(
                      icon: Icons.description_outlined,
                      title: 'Terms and conditions',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Save changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF1DB954)),
              ),
            ),
        ],
      ),
    );
  }
}
