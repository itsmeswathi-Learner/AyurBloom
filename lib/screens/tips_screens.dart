import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({Key? key}) : super(key: key);

  void _showAddTipDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Healing Tip"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: "Tip"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () async {
              final title = titleController.text.trim();
              final tip = contentController.text.trim();

              if (title.isNotEmpty && tip.isNotEmpty) {
                await FirebaseFirestore.instance.collection('tips').add({
                  'title': title,
                  'tip': tip,
                  'timestamp': Timestamp.now(),
                });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('💡 Healing Tips'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Tip',
            onPressed: () => _showAddTipDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tips')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('⚠️ Error loading tips'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tips = snapshot.data!.docs;

          if (tips.isEmpty) {
            return const Center(child: Text('🪴 No tips yet. Be the first!'));
          }

          return ListView.builder(
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final data = tips[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Text(data['tip'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
