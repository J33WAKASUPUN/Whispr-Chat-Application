import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whispr_chat_app/services/chat/notification_service.dart';
import '../services/auth/auth_service.dart';
import 'package:whispr_chat_app/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  bool _pushNotificationsEnabled = true;
  bool _soundNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled = prefs.getBool('pushNotificationsEnabled') ?? true;
      _soundNotificationsEnabled = prefs.getBool('soundNotificationsEnabled') ?? true;
    });
  }

  Future<void> _setPushNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotificationsEnabled', value);
    await _notificationService.setPushNotificationsEnabled(value);
    setState(() {
      _pushNotificationsEnabled = value;
    });
  }

  Future<void> _setSoundNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundNotificationsEnabled', value);
    await _notificationService.setSoundNotificationsEnabled(value);
    setState(() {
      _soundNotificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder(
        future: _authService.getCurrentUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data ?? {};

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Settings',
                  style: GoogleFonts.museoModerno(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return FlexibleSpaceBar(
                      background: LayoutBuilder(
                        builder: (context, constraints) {
                          final settings = context
                              .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
                          final deltaExtent = settings.maxExtent - settings.minExtent;
                          final t = (1.0 -
                                  (settings.currentExtent - settings.minExtent) / deltaExtent)
                              .clamp(0.0, 1.0);

                          final fadeOutFactor = (1.0 - (t * 1.5)).clamp(1.0, 1.0);

                          if (fadeOutFactor == 0) {
                            return const SizedBox.shrink();
                          }

                          return Opacity(
                            opacity: fadeOutFactor,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 65),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 45,
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      child: Text(
                                        (userData['username'] ?? 'U')[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    userData['username'] ?? 'User',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData['email'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Notifications',
                      style: GoogleFonts.museoModerno(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            _buildSettingSwitch(
                              context,
                              'Push Notifications',
                              _pushNotificationsEnabled,
                              _setPushNotificationsEnabled,
                            ),
                            const SizedBox(height: 8),
                            _buildSettingSwitch(
                              context,
                              'Sound Notifications',
                              _soundNotificationsEnabled,
                              _setSoundNotificationsEnabled,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Appearance',
                      style: GoogleFonts.museoModerno(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<AppTheme>(
                      builder: (context, themeProvider, _) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dark Mode',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Switch(
                                value: themeProvider.isDarkMode,
                                onChanged: (value) => themeProvider.toggleTheme(),
                                activeColor: Theme.of(context).colorScheme.primary,
                                activeTrackColor:
                                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                inactiveThumbColor: Theme.of(context).colorScheme.surface,
                                inactiveTrackColor:
                                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme Color',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildColorPicker(context),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingSwitch(
    BuildContext context,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          inactiveThumbColor: Theme.of(context).colorScheme.surface,
          inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildColorPicker(BuildContext context) {
    final List<Color> colors = [
      const Color(0xFF8B5CF6), // Violet (Purple)
      const Color(0xFF6366F1), // Indigo (Default)
      const Color(0xFF3B82F6), // Blue
      const Color.fromARGB(255, 34, 197, 61), // Green
      const Color.fromARGB(255, 250, 174, 21), // Yellow
      const Color(0xFFF97316), // Orange
      const Color(0xFFEF4444), // Red
      const Color(0xFFEC4899), // Pink
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: colors.map((color) {
        return Consumer<AppTheme>(
          builder: (context, themeProvider, _) => GestureDetector(
            onTap: () => themeProvider.updatePrimaryColor(color),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeProvider.primaryColor == color
                      ? Colors.white
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  if (themeProvider.primaryColor == color)
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
