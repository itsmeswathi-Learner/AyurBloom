// lib/screens/nearby_hospitals_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; // Import http
import 'dart:convert';

// Simple model for a Place/Hospital from Overpass
class Place {
  final double lat;
  final double lon;
  final String name;
  final String? address; // Might not always be available
  final String? amenityType; // e.g., 'hospital', 'clinic', 'pharmacy'

  Place({
    required this.lat,
    required this.lon,
    required this.name,
    this.address,
    this.amenityType,
  });

  // Factory constructor to create a Place from Overpass API JSON
  factory Place.fromJson(Map<String, dynamic> element) {
    // Overpass returns coordinates in 'center' or 'bounds' for some elements,
    // but often just 'lat' and 'lon' for nodes.
    double lat = 0.0;
    double lon = 0.0;

    if (element['lat'] != null && element['lon'] != null) {
      lat = (element['lat'] as num).toDouble();
      lon = (element['lon'] as num).toDouble();
    } else if (element['center'] != null) {
      lat = (element['center']['lat'] as num).toDouble();
      lon = (element['center']['lon'] as num).toDouble();
    }
    // Add more logic if needed for bounds etc.

    String name = element['tags']?['name'] ?? 'Unnamed';
    String? address = element['tags']?['addr:full'] ??
        (element['tags']?['addr:street'] != null
            ? '${element['tags']?['addr:street']}, ${element['tags']?['addr:city']}'
            : null);
    String? amenityType = element['tags']?['amenity'];

    return Place(
      lat: lat,
      lon: lon,
      name: name,
      address: address,
      amenityType: amenityType,
    );
  }
}

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;
  List<Place> _places = [];
  final String _searchRadius = '5000'; // Search radius in meters (5km)

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchHospitals();
  }

  Future<void> _getCurrentLocationAndFetchHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _places = []; // Clear previous results
    });

    try {
      // 1. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permissions denied.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions permanently denied.';
        });
        return;
      }

      // 2. Get current position
      Position position =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        _currentPosition = position;
      });

      // 3. Fetch nearby places (hospitals, clinics)
      await _fetchNearbyPlaces(position);
    } catch (e) {
      print("Error getting location or fetching places: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to get location or load places: $e';
      });
    }
  }

  Future<void> _fetchNearbyPlaces(Position position) async {
    // Overpass QL query to find hospitals, clinics, doctors near the user
    // IMPORTANT: Escape the $ signs in the regex with \$
    String overpassQuery = '''
      [out:json];
      (
        node["amenity"~"^(hospital|clinic|doctors)\$"](around:${_searchRadius},${position.latitude},${position.longitude});
        way["amenity"~"^(hospital|clinic|doctors)\$"](around:${_searchRadius},${position.latitude},${position.longitude});
        relation["amenity"~"^(hospital|clinic|doctors)\$"](around:${_searchRadius},${position.latitude},${position.longitude});
      );
      out center;
    ''';

    final Uri url = Uri.https('overpass-api.de', '/api/interpreter');

    try {
      // Encode the query for the request body
      final response = await http.post(
        url,
        headers: {'Content-Type': 'text/plain; charset=utf-8'}, // Overpass expects text/plain
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data['elements'] is List) {
          List<dynamic> elements = data['elements'];
          List<Place> places = elements.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();

          setState(() {
            _places = places;
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid response format from Overpass API');
        }
      } else {
        throw Exception('Overpass API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Handle potential CORS errors specifically if running on web
      String errorMsg = 'Failed to fetch nearby places: $e';
      // Check for CORS error in the string representation of the exception
      // Remove ClientException check and use string check instead
      if (e.toString().contains('CORS')) {
        errorMsg += "\n(CORS error - This is common on web. Consider backend proxy or testing on mobile.)";
      }
      print("Overpass API Error: $errorMsg");
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Hospitals & Clinics'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Display current coordinates for debugging/confirmation
            if (_currentPosition != null)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Your Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            // Refresh Button
            ElevatedButton.icon(
              onPressed: _getCurrentLocationAndFetchHospitals,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                                const SizedBox(height: 10),
                                Text(_errorMessage, textAlign: TextAlign.center),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _getCurrentLocationAndFetchHospitals,
                                  child: const Text('Retry'),
                                )
                              ],
                            ),
                          ),
                        )
                      : _places.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_hospital_outlined, size: 50, color: Colors.grey),
                                  SizedBox(height: 10),
                                  Text('No hospitals or clinics found nearby.'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _places.length,
                              itemBuilder: (context, index) {
                                final place = _places[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: Icon(
                                      place.amenityType == 'hospital'
                                          ? Icons.local_hospital
                                          : (place.amenityType == 'clinic' ? Icons.local_pharmacy : Icons.person),
                                      color: Colors.blue.shade700,
                                    ),
                                    title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      place.address ?? 'Address not available',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Optional: Add an icon button to open maps
                                    trailing: IconButton(
                                      icon: const Icon(Icons.map, color: Colors.green),
                                      onPressed: () {
                                        // Open in Google Maps (or preferred maps app)
                                        final Uri googleMapsUri = Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lon}',
                                        );
                                        // Note: url_launcher might be needed and added to pubspec.yaml if not already present
                                        // import 'package:url_launcher/url_launcher.dart';
                                        // if (await canLaunchUrl(googleMapsUri)) {
                                        //   await launchUrl(googleMapsUri);
                                        // } else {
                                        //   ScaffoldMessenger.of(context).showSnackBar(
                                        //     const SnackBar(content: Text('Could not open maps app')),
                                        //   );
                                        // }
                                        // For now, just show coordinates/snackbar
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Coordinates: ${place.lat}, ${place.lon}')),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}