import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isOnDuty = true;
  bool _notificationsEnabled = true;
  bool _locationSharing = true;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();

    // Check authentication
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
        debugPrint("No user logged in, redirecting to login");
      });
    }

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Map Firestore icon strings to Icons
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'favorite':
        return Icons.favorite;
      case 'school':
        return Icons.school;
      case 'build':
        return Icons.build;
      default:
        return Icons.info;
    }
  }

  // Convert hex string to Color
  Color _hexToColor(String hex) {
    try {
      final hexColor = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      debugPrint("Invalid hex color: $hex");
      return Colors.grey;
    }
  }

  // Show edit profile dialog
  Future<void> _showEditProfileDialog(Map<String, dynamic> userData) async {
    final nameController = TextEditingController(text: userData['name']);
    final phoneController = TextEditingController(text: userData['phone']);
    final emailController = TextEditingController(text: userData['email']);

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Edit Profile",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator:
                          (value) => value!.isEmpty ? "Name is required" : null,
                    ),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: "Phone"),
                      keyboardType: TextInputType.phone,
                      validator:
                          (value) =>
                              value!.isEmpty ? "Phone is required" : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return "Email is required";
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .update({
                            'name': nameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'email': emailController.text.trim(),
                          });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Profile updated")),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error updating profile: $e")),
                        );
                      }
                      debugPrint("Error updating profile: $e");
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save"),
              ),
            ],
          ),
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
  }

  // Handle action tiles
  Future<void> _handleAction(String title) async {
    switch (title) {
      case 'Edit Profile':
        final userDoc =
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .get();
        if (userDoc.exists && mounted) {
          _showEditProfileDialog(userDoc.data()!);
        }
        break;
      case 'Logout':
        try {
          await _auth.signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Logged out successfully")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error logging out: $e")));
          }
          debugPrint("Error logging out: $e");
        }
        break;
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title - Feature coming soon!")),
          );
        }
    }
  }

  Widget _buildProfileHeader(
    Map<String, dynamic>? userData,
    Map<String, dynamic>? stats,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.redAccent, Colors.red[700]!, Colors.red[800]!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[100],
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isOnDuty ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(
                        _isOnDuty ? Icons.check : Icons.pause,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData?['fullName'] ?? 'Loading...',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      userData?['role'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic>? userData) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information",
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            Icons.phone,
            "Phone",
            userData?['phone'] ?? 'Loading...',
          ),
          _buildInfoRow(
            Icons.email,
            "Email",
            userData?['email'] ?? 'Loading...',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.redAccent, size: 20),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Settings & Actions",
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.h),
          _buildSettingsTile(
            Icons.notifications,
            "Notifications",
            "Emergency alerts and updates",
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          _buildSettingsTile(
            Icons.location_on,
            "Location Sharing",
            "Share location for dispatch",
            _locationSharing,
            (value) => setState(() => _locationSharing = value),
          ),
          const Divider(height: 30),
          _buildActionTile(Icons.edit, "Edit Profile", Colors.blue),
          _buildActionTile(Icons.history, "Activity History", Colors.green),
          _buildActionTile(Icons.school, "Training Records", Colors.orange),
          _buildActionTile(Icons.settings, "App Settings", Colors.grey),
          _buildActionTile(Icons.help, "Help & Support", Colors.purple),
          _buildActionTile(Icons.logout, "Logout", Colors.red),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.sp,
        color: Colors.grey[400],
      ),
      onTap: () => _handleAction(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _auth.currentUser != null
                ? _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .snapshots()
                : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint("Error fetching user data: ${snapshot.error}");
            return Center(
              child: Text(
                "Error loading profile",
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "No profile data found",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final stats = userData['stats'] as Map<String, dynamic>?;

          return StreamBuilder<QuerySnapshot>(
            stream:
                _auth.currentUser != null
                    ? _firestore
                        .collection('users')
                        .doc(_auth.currentUser!.uid)
                        .collection('activities')
                        .orderBy('time', descending: true)
                        .limit(5)
                        .snapshots()
                    : null,
            builder: (context, activitySnapshot) {
              List<Map<String, dynamic>> activities = [];
              if (activitySnapshot.hasData) {
                activities =
                    activitySnapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'title': data['title'] ?? '',
                        'description': data['description'] ?? '',
                        'time':
                            (data['time'] as Timestamp?)?.toDate().toString() ??
                            '',
                        'status': data['status'] ?? '',
                        'icon': data['icon'] ?? 'info',
                        'color': data['color'] ?? '#000000',
                      };
                    }).toList();
              }

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProfileHeader(userData, stats),
                        _buildInfoSection(userData),
                        _buildSettingsSection(),
                        SizedBox(height: 20.sp),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
