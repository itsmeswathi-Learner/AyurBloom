import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../auth/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  User? user;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  int _currentStreak = 0;
  int _totalDays = 0;
  DateTime? _lastActiveDate;
  late AnimationController _streakAnimationController;
  late Animation<double> _streakAnimation;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadStreakData();
    
    // Initialize streak animation
    _streakAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _streakAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _streakAnimationController, curve: Curves.elasticOut),
    );
    _streakAnimationController.forward();
  }

  // Load streak data from SharedPreferences
  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = user?.uid;
    
    if (userId != null) {
      setState(() {
        _currentStreak = prefs.getInt('${userId}_current_streak') ?? 0;
        _totalDays = prefs.getInt('${userId}_total_days') ?? 0;
        
        final lastActiveDateString = prefs.getString('${userId}_last_active');
        if (lastActiveDateString != null) {
          _lastActiveDate = DateTime.parse(lastActiveDateString);
          _checkStreakValidity();
        }
      });
    }
  }

  // Check if streak is still valid based on last active date
  void _checkStreakValidity() {
    if (_lastActiveDate == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = DateTime(
      _lastActiveDate!.year, 
      _lastActiveDate!.month, 
      _lastActiveDate!.day
    );
    
    final daysDifference = today.difference(lastActive).inDays;
    
    // If more than 1 day has passed, reset streak
    if (daysDifference > 1) {
      setState(() {
        _currentStreak = 0;
      });
      _saveStreakData();
    }
  }

  // Record activity and update streak
  Future<void> _recordActivity() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if user already recorded activity today
    if (_lastActiveDate != null) {
      final lastActive = DateTime(
        _lastActiveDate!.year, 
        _lastActiveDate!.month, 
        _lastActiveDate!.day
      );
      
      if (today == lastActive) {
        // Already active today
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎯 You\'re already active today! Keep it up!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }
    
    // Calculate streak
    if (_lastActiveDate != null) {
      final lastActive = DateTime(
        _lastActiveDate!.year, 
        _lastActiveDate!.month, 
        _lastActiveDate!.day
      );
      final daysDifference = today.difference(lastActive).inDays;
      
      if (daysDifference == 1) {
        // Consecutive day - increment streak
        _currentStreak++;
      } else {
        // Gap in days - start new streak
        _currentStreak = 1;
      }
    } else {
      // First time activity
      _currentStreak = 1;
    }
    
    // Update data
    setState(() {
      _lastActiveDate = now;
      if (_currentStreak == 1 || (_lastActiveDate != null && 
          today.difference(DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day)).inDays == 1)) {
        _totalDays++;
      }
    });
    
    // Save to SharedPreferences
    await _saveStreakData();
    
    // Animate and celebrate
    _streakAnimationController.reset();
    _streakAnimationController.forward();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 8),
            Text('🔥 Streak updated to $_currentStreak days!'),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Save streak data to SharedPreferences
  Future<void> _saveStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = user?.uid;
    
    if (userId != null) {
      await prefs.setInt('${userId}_current_streak', _currentStreak);
      await prefs.setInt('${userId}_total_days', _totalDays);
      if (_lastActiveDate != null) {
        await prefs.setString('${userId}_last_active', _lastActiveDate!.toIso8601String());
      }
    }
  }

  @override
  void dispose() {
    _streakAnimationController.dispose();
    super.dispose();
  }

  // Profile picture selection with real image display
  Future<void> _updateProfilePicture() async {
    try {
      // Show image source selection
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.green.shade600),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.green.shade600),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _isLoading = true;
            _selectedImage = File(image.path);
          });

          // Simulate upload delay (replace with actual Firebase Storage upload)
          await Future.delayed(const Duration(seconds: 2));
          
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Profile picture updated successfully! 🎉'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // Dynamic streak widget
  Widget _buildStreakCard() {
    return AnimatedBuilder(
      animation: _streakAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _streakAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _currentStreak > 0 
                    ? [Colors.orange.shade400, Colors.deepOrange.shade600]
                    : [Colors.grey.shade400, Colors.grey.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _currentStreak > 0 
                      ? Colors.orange.shade200 
                      : Colors.grey.shade200,
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currentStreak > 0 
                            ? Icons.local_fire_department 
                            : Icons.flash_off,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentStreak > 0 ? '🔥 Current Streak' : '💤 No Streak Yet',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_currentStreak Days',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total active: $_totalDays days',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _recordActivity,
                    icon: const Icon(Icons.add_task, size: 18),
                    label: Text(
                      _currentStreak > 0 
                          ? 'Mark Today as Active' 
                          : 'Start Your Streak!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _currentStreak > 0 
                          ? Colors.orange.shade700 
                          : Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Info tile for editable fields
  Widget _buildInfoTile({
    required String title,
    required String value,
    required Future<void> Function(String) onEdit,
    TextInputType keyboardType = TextInputType.text,
    bool isEditable = true,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: isEditable 
              ? () => _editField(
                  title: title, 
                  currentValue: value, 
                  onSave: onEdit, 
                  keyboardType: keyboardType,
                )
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.green.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.green.shade600, size: 20),
                  ),
                  const SizedBox(width: 15),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value.isEmpty ? 'Tap to add' : value,
                        style: TextStyle(
                          color: value.isEmpty ? Colors.grey.shade500 : Colors.black87,
                          fontSize: 16,
                          fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isEditable ? Icons.edit_outlined : Icons.lock_outlined,
                  color: isEditable ? Colors.green.shade400 : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editField({
    required String title,
    required String currentValue,
    required Future<void> Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: currentValue);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit $title', style: TextStyle(color: Colors.green.shade700)),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Enter new $title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty && newValue != currentValue) {
                setState(() {
                  _isLoading = true;
                });
                Navigator.pop(context);
                try {
                  await onSave(newValue);
                  setState(() {
                    user = FirebaseAuth.instance.currentUser;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('$title updated successfully! ✨'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating $title: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = MediaQuery.of(context).size.width > 768 ? 100.0 : 20.0;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        body: const Center(
          child: Text(
            '⚠️ No user logged in',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('🌿 My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.green.shade700),
                const SizedBox(height: 16),
                Text(
                  'Updating your awesome profile... ✨',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              const SizedBox(height: 30),
              
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade300, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade200,
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (user?.photoURL?.isNotEmpty == true
                                ? NetworkImage(user!.photoURL!)
                                : const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png')),
                        backgroundColor: Colors.green.shade100,
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: _updateProfilePicture,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade600, Colors.green.shade800],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.camera_alt, 
                            size: 20, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // User Name
              Text(
                user?.displayName ?? 'Friend',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                user?.email ?? 'No Email',
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.green.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 30),
              
              // Dynamic Streak Card
              _buildStreakCard(),
              
              const SizedBox(height: 30),
              
              // Profile Information Card (Name and Email only)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100,
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    _buildInfoTile(
                      title: 'Name',
                      value: user!.displayName ?? '',
                      onEdit: (name) => user!.updateDisplayName(name),
                      icon: Icons.person,
                    ),
                    
                    _buildInfoTile(
                      title: 'Email',
                      value: user!.email ?? '',
                      onEdit: (value) async {
                        try {
                          await user!.verifyBeforeUpdateEmail(value);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.mail_outline, color: Colors.white),
                                    const SizedBox(width: 8),
                                    const Text('Verification email sent! 📧'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                      },
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.email,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Logout Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade200,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {
                    final bool? shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to logout? We\'ll miss you! 😢'),
                        actions: [
                          TextButton(
                            child: const Text('Stay', style: TextStyle(color: Colors.green)),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Logout', style: TextStyle(color: Colors.white)),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      await AuthService().logout();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
    );
  }
}