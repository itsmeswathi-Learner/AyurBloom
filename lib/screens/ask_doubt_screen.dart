import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AskDoubtScreen extends StatefulWidget {
  const AskDoubtScreen({Key? key}) : super(key: key);

  @override
  State<AskDoubtScreen> createState() => _AskDoubtScreenState();
}

class _AskDoubtScreenState extends State<AskDoubtScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchRemedies(String keyword) async {
    if (keyword.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = false;
      _searchResults.clear();
    });

    try {
      // Convert search keyword to lowercase for case-insensitive search
      String searchTerm = keyword.toLowerCase().trim();
      
      print('Searching for: $searchTerm'); // Debug print
      
      // Get all documents from knowledge_base collection
      QuerySnapshot querySnapshot = await _firestore
          .collection('knowledge_base')
          .get();

      print('Total documents found: ${querySnapshot.docs.length}'); // Debug print

      List<Map<String, dynamic>> matchedResults = [];

      // Filter documents based on keywords and other fields
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool hasMatch = false;
        
        print('Checking document: ${doc.id}'); // Debug print
        print('Document data: $data'); // Debug print
        
        // Check all string fields for matches
        data.forEach((key, value) {
          if (value is String && value.toLowerCase().contains(searchTerm)) {
            hasMatch = true;
            print('Match found in $key: $value'); // Debug print
          }
          
          // Check if it's a list (like keywords)
          if (value is List) {
            for (var item in value) {
              if (item.toString().toLowerCase().contains(searchTerm)) {
                hasMatch = true;
                print('Match found in $key array: $item'); // Debug print
              }
            }
          }
        });
        
        if (hasMatch) {
          matchedResults.add({
            'id': doc.id,
            ...data,
          });
          print('Added to results: ${doc.id}'); // Debug print
        }
      }

      print('Total matches found: ${matchedResults.length}'); // Debug print

      setState(() {
        _searchResults = matchedResults;
        _isLoading = false;
        _hasSearched = true;
      });

    } catch (e) {
      print('Error searching: $e'); // Debug print
      setState(() {
        _isLoading = false;
        _hasSearched = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching remedies: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Enter a keyword to search for remedies',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No remedies found for your search',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final remedy = _searchResults[index];
        return _buildRemedyCard(remedy);
      },
    );
  }

  Widget _buildRemedyCard(Map<String, dynamic> remedy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            if (remedy.containsKey('title'))
              Text(
                remedy['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Type
            if (remedy.containsKey('type'))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  remedy['type'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Advice
            if (remedy.containsKey('advice'))
              Text(
                remedy['advice'] ?? 'No advice available',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Keywords
            if (remedy.containsKey('keywords') && remedy['keywords'] != null)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (remedy['keywords'] as List<dynamic>)
                    .map((keyword) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            keyword.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Doubt - Find Remedies'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter keyword (e.g., dry skin, aloe vera, fever)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) => _searchRemedies(value),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _searchRemedies(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
}