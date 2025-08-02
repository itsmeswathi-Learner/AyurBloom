// lib/screens/health_journal_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class HealthJournalScreen extends StatefulWidget {
  const HealthJournalScreen({super.key});

  @override
  State<HealthJournalScreen> createState() => _HealthJournalScreenState();
}

class _HealthJournalScreenState extends State<HealthJournalScreen> {
  final User? _user = FirebaseAuth.instance.currentUser; // Get current user
  final TextEditingController _entryController = TextEditingController();
  late Stream<QuerySnapshot> _entriesStream; // Stream for real-time updates

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      // Create a stream to listen for journal entries
      _entriesStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('journalEntries')
          .orderBy('timestamp', descending: true) // Order by timestamp, newest first
          .snapshots();
    }
  }

  void _addEntry() async {
    String content = _entryController.text.trim();
    if (content.isNotEmpty && _user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('journalEntries')
            .add({
          'content': content,
          'timestamp': FieldValue.serverTimestamp(), // Server timestamp for sorting
          'date': DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()), // Formatted date/time
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry added successfully!')),
          );
        }
        _entryController.clear();
        Navigator.of(context).pop(); // Close the dialog
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add entry: $e')),
          );
        }
      }
    } else if (_user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add entries.')),
        );
      }
    }
  }

  void _showAddEntryDialog() {
    _entryController.clear(); // Clear text field for new entry
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Journal Entry'),
          content: TextField(
            controller: _entryController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'How are you feeling today? Any symptoms, meals, or activities?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addEntry,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health Journal'),
          backgroundColor: Colors.brown.shade700,
        ),
        body: const Center(
          child: Text('Please log in to view your journal.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Journal'),
        backgroundColor: Colors.brown.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEntryDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _entriesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Your journal is empty.\nTap + to add your first entry!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final entries = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              var entry = entries[index].data() as Map<String, dynamic>;
              Timestamp timestamp = entry['timestamp'];
              DateTime date = timestamp.toDate();
              String formattedDate = DateFormat.yMMMd().add_jm().format(date);
              String content = entry['content'] ?? 'No content';

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          // Placeholder for edit/delete actions
                          // IconButton(
                          //   icon: const Icon(Icons.edit, size: 18),
                          //   onPressed: () {
                          //     // Implement edit functionality
                          //   },
                          // ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(content),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        backgroundColor: Colors.brown.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }
}