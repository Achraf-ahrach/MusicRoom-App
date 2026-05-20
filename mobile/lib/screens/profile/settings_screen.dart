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

  // Public info
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  // Friends info
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _instagramController = TextEditingController();
  // Private info
  final _notesController = TextEditingController();
  final _realNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProfile());
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _instagramController.dispose();
    _notesController.dispose();
    _realNameController.dispose();
    super.dispose();
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

      // Public info
      final pub = profile?.publicInfo ?? {};
      _bioController.text = pub['bio']?.toString() ?? '';
      _locationController.text = pub['location']?.toString() ?? '';
      _websiteController.text = pub['website']?.toString() ?? '';
      // Friends info
      final fri = profile?.friendsInfo ?? {};
      _phoneController.text = fri['phone']?.toString() ?? '';
      _birthdayController.text = fri['birthday']?.toString() ?? '';
      _instagramController.text = fri['instagram']?.toString() ?? '';
      // Private info
      final prv = profile?.privateInfo ?? {};
      _notesController.text = prv['notes']?.toString() ?? '';
      _realNameController.text = prv['real_name']?.toString() ?? '';
    });
  }

  Future<void> _savePreferences() async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<UserProfileProvider>();
    final token = authProvider.currentUser?.accessToken;
    if (token == null) return;

    // Save profile info tiers
    final infoSuccess = await profileProvider.updateProfile(
      token,
      profileProvider.profile?.displayName ?? '',
      profileProvider.profile?.avatarUrl,
      publicInfo: {
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
      },
      friendsInfo: {
        'phone': _phoneController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'instagram': _instagramController.text.trim(),
      },
      privateInfo: {
        'notes': _notesController.text.trim(),
        'real_name': _realNameController.text.trim(),
      },
    );

    // Save music preferences
    final prefsSuccess = await profileProvider.updatePreferences(token, {
      'discovery_mode': _activeDiscovery ? 'active' : 'passive',
      'max_distance_km': _searchDistance.round(),
      'favorite_genres': _selectedGenres.toList()..sort(),
      'data_saver': _dataSaver,
      'offline_mode': _offlineMode,
      'explicit_content': _explicitContent,
      'private_session': _privateSession,
      'notifications_enabled': _notificationsEnabled,
    });

    if (prefsSuccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_mode', _offlineMode);
    }

    if (!mounted) return;

    final allOk = infoSuccess && prefsSuccess;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(allOk ? 'Settings saved' : 'Could not save settings'),
        backgroundColor: allOk ? Colors.green : Colors.red,
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

  Widget _buildPrivacySection({
    required IconData icon,
    required String title,
    required String visibilityNote,
    required Color accentColor,
    required List<Widget> fields,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Text(
            visibilityNote,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
            child: Column(children: fields),
          ),
        ),
      ],
    );
  }

  Widget _infoField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1DB954)),
              ),
            ),
          ),
        ],
      ),
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
              _buildPrivacySection(
                icon: Icons.public,
                title: 'Profile details',
                visibilityNote: 'This data will be shown to everyone.',
                accentColor: const Color(0xFF1DB954),
                fields: [
                  _infoField(label: 'Bio', controller: _bioController, hint: 'Tell the world about yourself…'),
                  _infoField(label: 'Location', controller: _locationController, hint: 'City, Country'),
                  _infoField(label: 'Website', controller: _websiteController, hint: 'https://…', keyboardType: TextInputType.url),
                ],
              ),
              _buildPrivacySection(
                icon: Icons.group,
                title: 'Close friends details',
                visibilityNote: 'This data is visible only when you follow each other.',
                accentColor: const Color(0xFFFFC107),
                fields: [
                  _infoField(label: 'Phone', controller: _phoneController, hint: '+1 234 567 890', keyboardType: TextInputType.phone),
                  _infoField(label: 'Birthday', controller: _birthdayController, hint: 'YYYY-MM-DD'),
                  _infoField(label: 'Instagram', controller: _instagramController, hint: '@username'),
                ],
              ),
              _buildPrivacySection(
                icon: Icons.lock,
                title: 'Private details',
                visibilityNote: 'Only you can view this data.',
                accentColor: const Color(0xFF9C27B0),
                fields: [
                  _infoField(label: 'Real name', controller: _realNameController, hint: 'Your legal name'),
                  _infoField(label: 'Notes', controller: _notesController, hint: 'Personal notes…'),
                ],
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
