// lib/screens/meditation_timer_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'dart:async';
// import 'package:audioplayers/audioplayers.dart'; // Uncomment if using sound effects

class MeditationTimerScreen extends StatefulWidget {
  const MeditationTimerScreen({super.key});

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const int _initialDuration = 10 * 60; // 10 minutes in seconds
  int _timeLeft = _initialDuration;
  bool _isRunning = false;
  late Timer _timer;
  final User? _user = FirebaseAuth.instance.currentUser; // Get current user
  // final AudioPlayer _audioPlayer = AudioPlayer(); // For gong sound (uncomment if needed)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _isRunning = false;
          timer.cancel();
          _onTimerComplete(); // Handle completion
        }
      });
    });
  }

  void _onTimerComplete() async {
    _playGong(); // Play sound when timer finishes
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Save session to Firebase if user is logged in
    if (_user != null) {
      try {
        int sessionDurationSeconds = _initialDuration; // Assuming full session
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('meditationSessions')
            .add({
          'durationSeconds': sessionDurationSeconds,
          'completedAt': FieldValue.serverTimestamp(),
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()), // Optional: formatted date
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session completed and saved!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save session: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session completed! Log in to save progress.')),
        );
      }
    }
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _timeLeft = _initialDuration;
    });
    _timer.cancel();
  }

  void _setTimer(int minutes) {
    setState(() {
      _timeLeft = minutes * 60;
      _isRunning = false;
    });
    _timer.cancel();
  }

  void _playGong() async {
    // You need to add a gong sound file (e.g., 'gong.mp3') to your assets
    // and configure pubspec.yaml accordingly.
    // For now, this is a placeholder.
    // await _audioPlayer.play(AssetSource('sounds/gong.mp3'));
    // Or play a system sound/alert if preferred.
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    // _audioPlayer.dispose(); // Uncomment if using AudioPlayer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Timer'),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer Display
            ScaleTransition(
              scale: _animation,
              child: Text(
                _formatTime(_timeLeft),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace', // Use monospace for digital clock look
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Quick Set Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDurationButton(5),
                _buildDurationButton(10),
                _buildDurationButton(15),
                _buildDurationButton(20),
              ],
            ),
            const SizedBox(height: 40),
            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Start/Pause Button
                ElevatedButton(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: _isRunning
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                  ),
                  child: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                // Reset Button
                ElevatedButton(
                  onPressed: _resetTimer,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.grey.shade700,
                  ),
                  child: const Icon(
                    Icons.refresh,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationButton(int minutes) {
    return OutlinedButton(
      onPressed: () => _setTimer(minutes),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
            color: _timeLeft == minutes * 60
                ? Colors.indigo.shade700
                : Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text('$minutes min'),
    );
  }
}