import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  // App Preferences
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  bool _autoUpdate = true;
  String _mapStyle = 'Standard';
  double _mapZoom = 15.0;

  // Notification Settings
  bool _emergencyAlerts = true;
  bool _shiftReminders = true;
  bool _trainingNotifications = true;
  bool _systemUpdates = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _alertTone = 'Emergency Siren';
  double _notificationVolume = 0.8;

  // Emergency Settings
  bool _quickDial911 = true;
  bool _autoLocationShare = true;
  bool _emergencyContacts = true;
  String _defaultHospital = 'Korle-Bu Teaching Hospital';
  String _backupHospital = 'Ridge Hospital';
  int _responseTimeout = 30;

  // Security Settings
  bool _biometricLogin = false;
  bool _autoLock = true;
  int _lockTimeout = 5;
  bool _dataEncryption = true;
  bool _anonymousReporting = false;

  // Data & Sync Settings
  bool _autoSync = true;
  bool _offlineMode = false;
  bool _dataCompression = true;
  String _syncFrequency = 'Real-time';
  bool _wifiOnlySync = false;

  // Performance Settings
  bool _lowPowerMode = false;
  bool _backgroundRefresh = true;
  String _locationAccuracy = 'High';
  bool _batteryOptimization = false;

  final List<String> _languages = [
    'English',
    'Luganda',
    'Swahili',
    'Twi',
    'French',
    'Arabic',
  ];

  final List<String> _mapStyles = [
    'Standard',
    'Satellite',
    'Hybrid',
    'Terrain',
  ];

  final List<String> _alertTones = [
    'Emergency Siren',
    'Medical Alert',
    'Classic Beep',
    'Urgent Tone',
    'Hospital Bell',
  ];

  final List<String> _hospitals = [
    'Korle-Bu Teaching Hospital',
    'Ridge Hospital',
    '37 Military Hospital',
    'University of Ghana Hospital',
    'La General Hospital',
  ];

  final List<String> _syncOptions = [
    'Real-time',
    'Every 5 minutes',
    'Every 15 minutes',
    'Every 30 minutes',
    'Manual only',
  ];

  final List<String> _locationAccuracyOptions = [
    'High',
    'Medium',
    'Low',
    'Battery Saver',
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.redAccent, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    IconData? icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Colors.grey[600], size: 20),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.redAccent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
    IconData? icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Colors.grey[600], size: 20),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: SizedBox.shrink(),
              items:
                  options.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    );
                  }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    IconData? icon,
    Color? iconColor,
    String? unit,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? Colors.grey[600], size: 20),
                SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                "${value.toStringAsFixed(unit == 'min' ? 0 : 1)}${unit ?? ''}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.redAccent,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.redAccent,
              overlayColor: Colors.redAccent.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Reset Settings",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            "Are you sure you want to reset all settings to default? This action cannot be undone.",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resetToDefaults();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Reset",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetToDefaults() {
    setState(() {
      // App Preferences
      _isDarkMode = false;
      _selectedLanguage = 'English';
      _autoUpdate = true;
      _mapStyle = 'Standard';
      _mapZoom = 15.0;

      // Notification Settings
      _emergencyAlerts = true;
      _shiftReminders = true;
      _trainingNotifications = true;
      _systemUpdates = false;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _alertTone = 'Emergency Siren';
      _notificationVolume = 0.8;

      // Emergency Settings
      _quickDial911 = true;
      _autoLocationShare = true;
      _emergencyContacts = true;
      _defaultHospital = 'Korle-Bu Teaching Hospital';
      _backupHospital = 'Ridge Hospital';
      _responseTimeout = 30;

      // Security Settings
      _biometricLogin = false;
      _autoLock = true;
      _lockTimeout = 5;
      _dataEncryption = true;
      _anonymousReporting = false;

      // Data & Sync Settings
      _autoSync = true;
      _offlineMode = false;
      _dataCompression = true;
      _syncFrequency = 'Real-time';
      _wifiOnlySync = false;

      // Performance Settings
      _lowPowerMode = false;
      _backgroundRefresh = true;
      _locationAccuracy = 'High';
      _batteryOptimization = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Settings reset to defaults"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  "Settings",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.redAccent,
                        Colors.red[700]!,
                        Colors.red[800]!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Preferences
                    _buildSectionHeader("App Preferences", Icons.settings),
                    _buildSettingsCard(
                      children: [
                        _buildSwitchTile(
                          title: "Dark Mode",
                          subtitle: "Switch between light and dark theme",
                          value: _isDarkMode,
                          onChanged:
                              (value) => setState(() => _isDarkMode = value),
                          icon: Icons.dark_mode,
                          iconColor: Colors.indigo,
                        ),
                        _buildDropdownTile(
                          title: "Language",
                          subtitle: "Select your preferred language",
                          value: _selectedLanguage,
                          options: _languages,
                          onChanged: (value) {
                            setState(() => _selectedLanguage = value!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Language changed to $value"),
                              ),
                            );
                          },
                          icon: Icons.language,
                          iconColor: Colors.blue,
                        ),
                        _buildSwitchTile(
                          title: "Auto Update",
                          subtitle: "Automatically update app content",
                          value: _autoUpdate,
                          onChanged:
                              (value) => setState(() => _autoUpdate = value),
                          icon: Icons.update,
                          iconColor: Colors.green,
                        ),
                        _buildDropdownTile(
                          title: "Map Style",
                          subtitle: "Choose default map appearance",
                          value: _mapStyle,
                          options: _mapStyles,
                          onChanged:
                              (value) => setState(() => _mapStyle = value!),
                          icon: Icons.map,
                          iconColor: Colors.teal,
                        ),
                        _buildSliderTile(
                          title: "Default Map Zoom",
                          subtitle: "Set preferred zoom level",
                          value: _mapZoom,
                          min: 10.0,
                          max: 20.0,
                          onChanged:
                              (value) => setState(() => _mapZoom = value),
                          icon: Icons.zoom_in,
                          iconColor: Colors.purple,
                        ),
                      ],
                    ),

                    // Notification Settings
                    _buildSectionHeader("Notifications", Icons.notifications),
                    _buildSettingsCard(
                      children: [
                        _buildSwitchTile(
                          title: "Emergency Alerts",
                          subtitle: "Critical emergency notifications",
                          value: _emergencyAlerts,
                          onChanged:
                              (value) =>
                                  setState(() => _emergencyAlerts = value),
                          icon: Icons.warning,
                          iconColor: Colors.red,
                        ),
                        _buildSwitchTile(
                          title: "Shift Reminders",
                          subtitle: "Notifications about shift changes",
                          value: _shiftReminders,
                          onChanged:
                              (value) =>
                                  setState(() => _shiftReminders = value),
                          icon: Icons.schedule,
                          iconColor: Colors.orange,
                        ),
                        _buildSwitchTile(
                          title: "Training Notifications",
                          subtitle: "Updates about training sessions",
                          value: _trainingNotifications,
                          onChanged:
                              (value) => setState(
                                () => _trainingNotifications = value,
                              ),
                          icon: Icons.school,
                          iconColor: Colors.blue,
                        ),
                        _buildSwitchTile(
                          title: "System Updates",
                          subtitle: "App and system notifications",
                          value: _systemUpdates,
                          onChanged:
                              (value) => setState(() => _systemUpdates = value),
                          icon: Icons.system_update,
                          iconColor: Colors.indigo,
                        ),
                        _buildSwitchTile(
                          title: "Sound",
                          subtitle: "Enable notification sounds",
                          value: _soundEnabled,
                          onChanged:
                              (value) => setState(() => _soundEnabled = value),
                          icon: Icons.volume_up,
                          iconColor: Colors.green,
                        ),
                        _buildSwitchTile(
                          title: "Vibration",
                          subtitle: "Enable notification vibration",
                          value: _vibrationEnabled,
                          onChanged:
                              (value) =>
                                  setState(() => _vibrationEnabled = value),
                          icon: Icons.vibration,
                          iconColor: Colors.purple,
                        ),
                        _buildDropdownTile(
                          title: "Alert Tone",
                          subtitle: "Choose emergency alert sound",
                          value: _alertTone,
                          options: _alertTones,
                          onChanged:
                              (value) => setState(() => _alertTone = value!),
                          icon: Icons.music_note,
                          iconColor: Colors.pink,
                        ),
                        _buildSliderTile(
                          title: "Notification Volume",
                          subtitle: "Adjust alert volume level",
                          value: _notificationVolume,
                          min: 0.0,
                          max: 1.0,
                          onChanged:
                              (value) =>
                                  setState(() => _notificationVolume = value),
                          icon: Icons.volume_up,
                          iconColor: Colors.cyan,
                        ),
                      ],
                    ),

                    // Emergency Settings
                    _buildSectionHeader(
                      "Emergency Settings",
                      Icons.local_hospital,
                    ),
                    _buildSettingsCard(
                      children: [
                        _buildSwitchTile(
                          title: "Quick Dial Emergency",
                          subtitle: "Enable one-tap emergency calling",
                          value: _quickDial911,
                          onChanged:
                              (value) => setState(() => _quickDial911 = value),
                          icon: Icons.phone,
                          iconColor: Colors.red,
                        ),
                        _buildSwitchTile(
                          title: "Auto Location Share",
                          subtitle:
                              "Automatically share location in emergencies",
                          value: _autoLocationShare,
                          onChanged:
                              (value) =>
                                  setState(() => _autoLocationShare = value),
                          icon: Icons.location_on,
                          iconColor: Colors.blue,
                        ),
                        _buildSwitchTile(
                          title: "Emergency Contacts",
                          subtitle: "Enable emergency contact notifications",
                          value: _emergencyContacts,
                          onChanged:
                              (value) =>
                                  setState(() => _emergencyContacts = value),
                          icon: Icons.contacts,
                          iconColor: Colors.green,
                        ),
                        _buildDropdownTile(
                          title: "Default Hospital",
                          subtitle: "Primary hospital for emergencies",
                          value: _defaultHospital,
                          options: _hospitals,
                          onChanged:
                              (value) =>
                                  setState(() => _defaultHospital = value!),
                          icon: Icons.local_hospital,
                          iconColor: Colors.red,
                        ),
                        _buildDropdownTile(
                          title: "Backup Hospital",
                          subtitle: "Secondary hospital option",
                          value: _backupHospital,
                          options: _hospitals,
                          onChanged:
                              (value) =>
                                  setState(() => _backupHospital = value!),
                          icon: Icons.backup,
                          iconColor: Colors.orange,
                        ),
                        _buildSliderTile(
                          title: "Response Timeout",
                          subtitle: "Maximum wait time for response",
                          value: _responseTimeout.toDouble(),
                          min: 10.0,
                          max: 60.0,
                          onChanged:
                              (value) => setState(
                                () => _responseTimeout = value.round(),
                              ),
                          icon: Icons.timer,
                          iconColor: Colors.purple,
                          unit: " sec",
                        ),
                      ],
                    ),

                    // Security Settings
                    _buildSectionHeader("Security & Privacy", Icons.security),
                    _buildSettingsCard(
                      children: [
                        _buildSwitchTile(
                          title: "Biometric Login",
                          subtitle: "Use fingerprint or face unlock",
                          value: _biometricLogin,
                          onChanged:
                              (value) =>
                                  setState(() => _biometricLogin = value),
                          icon: Icons.fingerprint,
                          iconColor: Colors.blue,
                        ),
                        _buildSwitchTile(
                          title: "Auto Lock",
                          subtitle: "Automatically lock app when inactive",
                          value: _autoLock,
                          onChanged:
                              (value) => setState(() => _autoLock = value),
                          icon: Icons.lock,
                          iconColor: Colors.orange,
                        ),
                        _buildSliderTile(
                          title: "Lock Timeout",
                          subtitle: "Time before auto lock activates",
                          value: _lockTimeout.toDouble(),
                          min: 1.0,
                          max: 30.0,
                          onChanged:
                              (value) =>
                                  setState(() => _lockTimeout = value.round()),
                          icon: Icons.lock_clock,
                          iconColor: Colors.red,
                          unit: " min",
                        ),
                        _buildSwitchTile(
                          title: "Data Encryption",
                          subtitle: "Encrypt sensitive data",
                          value: _dataEncryption,
                          onChanged:
                              (value) =>
                                  setState(() => _dataEncryption = value),
                          icon: Icons.enhanced_encryption,
                          iconColor: Colors.green,
                        ),
                        _buildSwitchTile(
                          title: "Anonymous Reporting",
                          subtitle: "Allow anonymous crash reports",
                          value: _anonymousReporting,
                          onChanged:
                              (value) =>
                                  setState(() => _anonymousReporting = value),
                          icon: Icons.privacy_tip,
                          iconColor: Colors.purple,
                        ),
                      ],
                    ),

                    // Data & Sync Settings
                    _buildSectionHeader("Data & Sync", Icons.sync),
                    _buildSettingsCard(
                      children: [
                        _buildSwitchTile(
                          title: "Auto Sync",
                          subtitle: "Automatically sync data",
                          value: _autoSync,
                          onChanged:
                              (value) => setState(() => _autoSync = value),
                          icon: Icons.sync,
                          iconColor: Colors.blue,
                        ),
                        _buildSwitchTile(
                          title: "Offline Mode",
                          subtitle: "Enable offline functionality",
                          value: _offlineMode,
                          onChanged:
                              (value) => setState(() => _offlineMode = value),
                          icon: Icons.offline_pin,
                          iconColor: Colors.grey,
                        ),
                        _buildSwitchTile(
                          title: "Data Compression",
                          subtitle: "Compress data to save bandwidth",
                          value: _dataCompression,
                          onChanged:
                              (value) =>
                                  setState(() => _dataCompression = value),
                          icon: Icons.compress,
                          iconColor: Colors.green,
                        ),
                        _buildDropdownTile(
                          title: "Sync Frequency",
                          subtitle: "How often to sync data",
                          value: _syncFrequency,
                          options: _syncOptions,
                          onChanged:
                              (value) =>
                                  setState(() => _syncFrequency = value!),
                          icon: Icons.refresh,
                          iconColor: Colors.orange,
                        ),
                        _buildSwitchTile(
                          title: "WiFi Only Sync",
                          subtitle: "Only sync when connected to WiFi",
                          value: _wifiOnlySync,
                          onChanged:
                              (value) => setState(() => _wifiOnlySync = value),
                          icon: Icons.wifi,
                          iconColor: Colors.blue,
                        ),
                      ],
                    ),

                    // Performance Settings
                    _buildSectionHeader("Performance", Icons.speed),
                    _buildSettingsCard(
                      children: [
                        _buildSwitchTile(
                          title: "Low Power Mode",
                          subtitle: "Reduce battery usage",
                          value: _lowPowerMode,
                          onChanged:
                              (value) => setState(() => _lowPowerMode = value),
                          icon: Icons.battery_saver,
                          iconColor: Colors.orange,
                        ),
                        _buildSwitchTile(
                          title: "Background Refresh",
                          subtitle: "Allow app to refresh in background",
                          value: _backgroundRefresh,
                          onChanged:
                              (value) =>
                                  setState(() => _backgroundRefresh = value),
                          icon: Icons.refresh,
                          iconColor: Colors.green,
                        ),
                        _buildDropdownTile(
                          title: "Location Accuracy",
                          subtitle: "GPS accuracy vs battery life",
                          value: _locationAccuracy,
                          options: _locationAccuracyOptions,
                          onChanged:
                              (value) =>
                                  setState(() => _locationAccuracy = value!),
                          icon: Icons.gps_fixed,
                          iconColor: Colors.blue,
                        ),
                        _buildSwitchTile(
                          title: "Battery Optimization",
                          subtitle: "Optimize for longer battery life",
                          value: _batteryOptimization,
                          onChanged:
                              (value) =>
                                  setState(() => _batteryOptimization = value),
                          icon: Icons.battery_charging_full,
                          iconColor: Colors.green,
                        ),
                      ],
                    ),

                    // Action Items
                    _buildSectionHeader("Actions", Icons.build),
                    _buildSettingsCard(
                      children: [
                        _buildActionTile(
                          title: "Export Settings",
                          subtitle: "Backup your current settings",
                          icon: Icons.download,
                          iconColor: Colors.blue,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Settings exported successfully"),
                              ),
                            );
                          },
                        ),
                        _buildActionTile(
                          title: "Import Settings",
                          subtitle: "Restore settings from backup",
                          icon: Icons.upload,
                          iconColor: Colors.green,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Import feature coming soon"),
                              ),
                            );
                          },
                        ),
                        _buildActionTile(
                          title: "Reset Settings",
                          subtitle: "Restore all settings to default",
                          icon: Icons.restore,
                          iconColor: Colors.red,
                          onTap: _showResetDialog,
                        ),
                        _buildActionTile(
                          title: "About",
                          subtitle: "App version and information",
                          icon: Icons.info,
                          iconColor: Colors.grey,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Text(
                                      "Emergency Response App",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Version: 1.0.0",
                                          style: GoogleFonts.poppins(),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Developed for emergency medical services",
                                          style: GoogleFonts.poppins(),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "© 2024 Emergency Response Team",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          "Close",
                                          style: GoogleFonts.poppins(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
