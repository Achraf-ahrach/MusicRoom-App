import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Discovery Mode Toggles
  bool _activeDiscovery = true;
  double _searchDistance = 50.0;
  
  // App settings toggles
  bool _dataSaver = false;
  bool _offlineMode = false;
  bool _explicitContent = true;

  @override
  void initState() {
    super.initState();
    // Load existing settings if available
    final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final prefs = profileProvider.profile?.musicPreferences ?? {};
    if (prefs.isNotEmpty) {
      _activeDiscovery = prefs['discovery_mode'] == 'active';
      _searchDistance = (prefs['max_distance_km'] ?? 50.0).toDouble();
    }
  }

  void _savePreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final token = authProvider.currentUser?.accessToken;

    if (token != null) {
      final success = await profileProvider.updatePreferences(token, {
        'discovery_mode': _activeDiscovery ? 'active' : 'passive',
        'max_distance_km': _searchDistance.toInt(),
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save settings'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile({required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildToggle({required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return _buildListTile(
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: (val) {
          onChanged(val);
          _savePreferences();
        },
        activeColor: const Color(0xFF1DB954), // Spotify Green
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Account Profile Section
          Consumer<UserProfileProvider>(
            builder: (context, provider, child) {
              final user = provider.profile;
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
                title: Text(user?.displayName ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: const Text('View profile', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => Navigator.pushNamed(context, '/edit_profile'),
              );
            },
          ),
          
          const Divider(color: Colors.white24, indent: 16, endIndent: 16, height: 32),

          _buildSectionHeader('Music Preferences'),
          _buildToggle(
            title: 'Active Discovery',
            subtitle: 'Allow discovering new songs and events matching your genres',
            value: _activeDiscovery,
            onChanged: (v) => setState(() => _activeDiscovery = v),
          ),
          ListTile(
            title: const Text('Search Distance', style: TextStyle(color: Colors.white, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('${_searchDistance.toInt()} km', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                Slider(
                  value: _searchDistance,
                  min: 10,
                  max: 500,
                  divisions: 49,
                  activeColor: const Color(0xFF1DB954),
                  inactiveColor: Colors.grey[800],
                  onChanged: (v) => setState(() => _searchDistance = v),
                  onChangeEnd: (v) => _savePreferences(),
                ),
              ],
            ),
          ),

          _buildSectionHeader('Data Saver'),
          _buildToggle(
            title: 'Data Saver',
            subtitle: 'Sets your audio quality to low and disables artist canvases',
            value: _dataSaver,
            onChanged: (v) => setState(() => _dataSaver = v),
          ),

          _buildSectionHeader('Playback'),
          _buildToggle(
            title: 'Offline mode',
            subtitle: 'When you go offline, you\'ll only be able to play the music you\'ve downloaded.',
            value: _offlineMode,
            onChanged: (v) => setState(() => _offlineMode = v),
          ),
          _buildToggle(
            title: 'Allow Explicit Content',
            subtitle: 'Turn on to play explicit content',
            value: _explicitContent,
            onChanged: (v) => setState(() => _explicitContent = v),
          ),

          _buildSectionHeader('About'),
          _buildListTile(title: 'Version', trailing: Text('1.0.0', style: TextStyle(color: Colors.grey[600]))),
          _buildListTile(title: 'Terms and Conditions'),
          _buildListTile(title: 'Privacy Policy'),

          const SizedBox(height: 32),
          
          // Log Out Button
          Center(
            child: TextButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('Log out', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}