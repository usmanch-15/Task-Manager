import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/theme_manager.dart';
import '../database/database_helper.dart';
import '../utils/export_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedSound = 'Default';
  final List<String> _notificationSounds = ['Default', 'Chime', 'Alert', 'Bell'];

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Color(0xFF1A1A1A), Color(0xFF2C2C2C)]
                : [Color(0xFFF5F7FF), Colors.white],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Appearance Section
            _buildSection(
              title: 'Appearance',
              icon: Icons.palette,
              children: [
                SwitchListTile(
                  title: Text('Dark Mode'),
                  subtitle: Text('Switch to dark theme'),
                  value: themeManager.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeManager.toggleTheme(value);
                  },
                  activeColor: Color(0xFF6C63FF),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Notifications Section
            _buildSection(
              title: 'Notifications',
              icon: Icons.notifications,
              children: [
                SwitchListTile(
                  title: Text('Enable Notifications'),
                  subtitle: Text('Get reminders for tasks'),
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final status = await Permission.notification.request();
                      if (status.isGranted) {
                        setState(() => _notificationsEnabled = value);
                      }
                    } else {
                      setState(() => _notificationsEnabled = value);
                    }
                  },
                  activeColor: Color(0xFF6C63FF),
                ),
                if (_notificationsEnabled)
                  ListTile(
                    title: Text('Notification Sound'),
                    subtitle: Text(_selectedSound),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        setState(() {
                          _selectedSound = value;
                        });
                      },
                      itemBuilder: (context) {
                        return _notificationSounds.map((sound) {
                          return PopupMenuItem(
                            value: sound,
                            child: Text(sound),
                          );
                        }).toList();
                      },
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Data Management Section
            _buildSection(
              title: 'Data Management',
              icon: Icons.data_usage,
              children: [
                ListTile(
                  leading: Icon(Icons.backup, color: Color(0xFF6C63FF)),
                  title: Text('Export as CSV'),
                  subtitle: Text('Save tasks as CSV file'),
                  onTap: () async {
                    final tasks = await DatabaseHelper().getTasks();
                    ExportService.exportAsCSV(tasks);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Color(0xFF6C63FF)),
                  title: Text('Export as PDF'),
                  subtitle: Text('Generate PDF report'),
                  onTap: () async {
                    final tasks = await DatabaseHelper().getTasks();
                    ExportService.exportAsPDF(tasks);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.share, color: Color(0xFF6C63FF)),
                  title: Text('Share via Email'),
                  subtitle: Text('Send tasks via email'),
                  onTap: () async {
                    final tasks = await DatabaseHelper().getTasks();
                    ExportService.shareViaEmail(tasks);
                  },
                ),
              ],
            ),
            SizedBox(height: 16),

            // About Section - 🔥 FIXED HERE
            _buildSection(
              title: 'About',
              icon: Icons.info,
              children: [
                // 🔥 FIXED: Changed Icons.version to Icons.info or Icons.label
                ListTile(
                  leading: Icon(Icons.info_outline, color: Color(0xFF6C63FF)),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: Icon(Icons.star_border, color: Color(0xFF6C63FF)),
                  title: Text('Rate App'),
                  onTap: () {
                    // Implement rate app functionality
                    _showComingSoonSnackBar('Rate App');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.share, color: Color(0xFF6C63FF)),
                  title: Text('Share App'),
                  onTap: () {
                    Share.share('Check out this awesome Task Manager App! https://play.google.com/store/apps/details?id=com.example.task_manager');
                  },
                ),
                // Add more about options
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: Color(0xFF6C63FF)),
                  title: Text('Privacy Policy'),
                  onTap: () {
                    _showComingSoonSnackBar('Privacy Policy');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.help, color: Color(0xFF6C63FF)),
                  title: Text('Help & Support'),
                  onTap: () {
                    _showComingSoonSnackBar('Help & Support');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            (Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF2C2C2C)
                : Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF6C63FF), size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0),
          ...children,
        ],
      ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}