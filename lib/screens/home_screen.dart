// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart'; // For location
import 'package:geocoding/geocoding.dart'; // For reverse geocoding
import 'package:http/http.dart' as http; // For API calls
// --- Import your other screens ---
import 'package:ayurbloom/screens/detail_screen.dart';
import 'package:ayurbloom/screens/ask_doubt_screen.dart';
import 'package:ayurbloom/screens/profile_screen.dart';
import 'package:ayurbloom/screens/meditation_timer_screen.dart';
import 'package:ayurbloom/screens/health_journal_screen.dart';
import 'package:ayurbloom/screens/medical_treatment_screen.dart';

// --- IMPORTANT: REPLACE WITH YOUR ACTUAL API KEY ---
const String _openWeatherMapApiKey = '303ceceead7788eb403c5458bae60fe7';
// --- END API KEY ---

class FeatureItem {
  final String title;
  final String imageUrl;
  final String contentType;
  final IconData icon;
  final Color color;
  final String description;

  FeatureItem(this.title, this.imageUrl, this.contentType, this.icon, this.color, this.description);
}

class HealthMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  HealthMetric(this.title, this.value, this.icon, this.color, {this.onTap});
}

class Mantra {
  final String name;
  final String sanskrit;
  final String meaning;
  final String benefits;
  final int recommendedCount;

  Mantra({
    required this.name,
    required this.sanskrit,
    required this.meaning,
    required this.benefits,
    required this.recommendedCount,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  PageController _pageController = PageController();
  int _currentQuoteIndex = 0;

  // --- Health Tracking Variables ---
  int _stepCount = 0;
  int _waterIntake = 0;
  int _meditationMinutes = 0;
  String _bloodPressure = "N/A";
  double _wellnessScore = 75.0; // This is calculated but not displayed anymore

  StreamSubscription<StepCount>? _stepCountStream;
  static const String _stepCountKey = 'step_count';
  static const String _waterIntakeKey = 'water_intake';
  static const String _meditationKey = 'meditation_minutes';
  static const String _lastDateKey = 'last_date';
  static const String _bpKey = 'blood_pressure';

  final List<Mantra> _mantras = [
    Mantra(
      name: "Om Mani Padme Hum",
      sanskrit: "ॐ मणि पद्मे हूँ",
      meaning: "The jewel in the lotus",
      benefits: "Purifies negative emotions, brings compassion and wisdom",
      recommendedCount: 108,
    ),
    Mantra(
      name: "Gayatri Mantra",
      sanskrit: "ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्",
      meaning: "We meditate on the divine light of the sun that illuminates our intellect",
      benefits: "Enhances wisdom, spiritual growth, and mental clarity",
      recommendedCount: 108,
    ),
    Mantra(
      name: "Om Gam Ganapataye Namaha",
      sanskrit: "ॐ गं गणपतये नमः",
      meaning: "Salutations to Lord Ganesha",
      benefits: "Removes obstacles, brings success and good fortune",
      recommendedCount: 21,
    ),
    Mantra(
      name: "So Hum",
      sanskrit: "सो हम्",
      meaning: "I am that",
      benefits: "Self-realization, inner peace, and spiritual awakening",
      recommendedCount: 108,
    ),
    Mantra(
      name: "Om Namah Shivaya",
      sanskrit: "ॐ नमः शिवाय",
      meaning: "I bow to Shiva",
      benefits: "Inner transformation, peace, and spiritual protection",
      recommendedCount: 108,
    ),
  ];

  final List<FeatureItem> features = [
    FeatureItem(
      "Yoga",
      "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=300&fit=crop",
      "yoga",
      Icons.self_improvement,
      const Color(0xFF6B73FF),
      "Ancient practice for mind-body wellness",
    ),
    FeatureItem(
      "Ayurveda",
      "https://images.unsplash.com/photo-1506619216599-9d16d0903dfd?w=400&h=300&fit=crop",
      "ayurveda",
      Icons.local_florist,
      const Color(0xFF9C27B0),
      "Traditional Indian system of medicine",
    ),
    FeatureItem(
      "Home Remedies",
      "https://images.unsplash.com/photo-1564093497595-593b96d80180?w=400&h=300&fit=crop",
      "home_remedies",
      Icons.home_work,
      const Color(0xFF00BCD4),
      "Natural healing solutions at home",
    ),
    // --- Updated Naturopathy Image ---
    FeatureItem(
      "Naturopathy",
      "https://images.unsplash.com/photo-1492076558080-7ad25252c662?w=400&h=300&fit=crop", // Specific nature image
      "naturopathy",
      Icons.eco,
      const Color(0xFF4CAF50),
      "Healing power of nature",
    ),
    FeatureItem(
      "Acupuncture",
      "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&h=300&fit=crop",
      "acupuncture",
      Icons.healing,
      const Color(0xFFFF9800),
      "Traditional Chinese medicine technique",
    ),
    FeatureItem(
      "Healing Diet",
      "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop",
      "diet",
      Icons.restaurant_menu,
      const Color(0xFFE91E63),
      "Nutrition for optimal health",
    ),
  ];

  final List<String> quotes = [
    "The body achieves what the mind believes.",
    "Yoga is the journey of the self, through the self, to the self.",
    "Let food be thy medicine and medicine be thy food.",
    "Nature itself is the best physician.",
    "To keep the body in good health is a duty.",
    "Health is not valued till sickness comes.",
    "The greatest wealth is health.",
  ];

  // --- Weather ---
  String _city = 'Detecting...'; // Default while fetching
  double? _temp;
  String? _cond;
  String? _weatherTip;
  final _cityCtrl = TextEditingController();

  String getWeatherBasedTip(String? condition, double? temperature) {
    if (condition == null || temperature == null) return 'Stay healthy and hydrated!';
    final temp = temperature.round();
    final cond = condition.toLowerCase();
    if (cond.contains('rain') || cond.contains('storm')) {
      return 'Perfect time for indoor meditation and breathing exercises! ☔';
    } else if (cond.contains('sunny') && temp > 30) {
      return 'Hot weather! Drink cooling herbal teas like mint or fennel. 🌞';
    } else if (cond.contains('sunny') && temp <= 30) {
      return 'Great weather for outdoor yoga and morning walks! ☀️';
    } else if (cond.contains('cloud') || cond.contains('overcast')) {
      return 'Cloudy day perfect for gentle yoga and Ayurvedic self-massage. ☁️';
    } else if (temp < 15) {
      return 'Cold weather! Try warming spices like ginger and turmeric tea. 🥶';
    } else if (cond.contains('wind')) {
      return 'Windy day! Practice calming pranayama breathing techniques. 💨';
    } else if (cond.contains('humid')) {
      return 'High humidity! Stay cool with coconut water and light meals. 💧';
    } else {
      return 'Perfect day to connect with nature and practice mindfulness! 🌿';
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
    _loadHealthData();
    _initPedometer();
    _fetchInitialLocationAndWeather(); // Fetch location and weather on start
    _animationController?.forward();
    _startQuoteRotation();
    _calculateWellnessScore();
  }

  Future<void> _loadHealthData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_lastDateKey) ?? '';

    if (lastDate != today) {
      await prefs.setString(_lastDateKey, today);
      await prefs.setInt(_stepCountKey, 0);
      await prefs.setInt(_waterIntakeKey, 0);
    }

    setState(() {
      _stepCount = prefs.getInt(_stepCountKey) ?? 0;
      _waterIntake = prefs.getInt(_waterIntakeKey) ?? 0;
      _meditationMinutes = prefs.getInt(_meditationKey) ?? 0;
      _bloodPressure = prefs.getString(_bpKey) ?? "N/A";
    });
  }

  Future<void> _initPedometer() async {
    var status = await Permission.activityRecognition.request();
    print("Permission status: $status");
    if (status.isGranted) {
      _stepCountStream = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            _stepCount = event.steps;
          });
          await prefs.setInt(_stepCountKey, _stepCount);
          _calculateWellnessScore();
        },
        onError: (error) {
          print('Step counter error: $error');
        },
      );
    } else {
      print('Permission denied for activity recognition.');
    }
  }

  void _calculateWellnessScore() {
    double score = 0;
    if (_stepCount >= 10000) score += 30;
    else score += (_stepCount / 10000) * 30;

    if (_waterIntake >= 8) score += 30;
    else score += (_waterIntake / 8) * 30;

    if (_meditationMinutes >= 20) score += 20;
    else score += (_meditationMinutes / 20) * 20;

    if (_bloodPressure != "N/A") {
      score += 20;
    }
    setState(() {
      _wellnessScore = score.clamp(0, 100);
    });
  }

  void _addWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterIntake++;
    });
    await prefs.setInt(_waterIntakeKey, _waterIntake);
    _calculateWellnessScore();
    _showWaterDialog();
  }

  void _showWaterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('💧', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Great Job!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You drank $_waterIntake glass${_waterIntake > 1 ? 'es' : ''} of water today!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              _waterIntake >= 8
                  ? '🎉 You\'ve reached your daily goal!'
                  : 'Keep going! Target: 8 glasses daily',
              style: TextStyle(
                color: _waterIntake >= 8 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue', style: TextStyle(color: Colors.blue.shade700)),
          ),
        ],
      ),
    );
  }

  void _addMeditationTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _meditationMinutes += 5;
    });
    await prefs.setInt(_meditationKey, _meditationMinutes);
    _calculateWellnessScore();
    _showMantraDialog();
  }

  void _showMantraDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '_POWERFUL MANTRAS_',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Chanting these mantras can enhance focus, peace, and spiritual well-being. Recommended counts are guidelines.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _mantras.length,
                  itemBuilder: (context, index) {
                    final mantra = _mantras[index];
                    return Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  mantra.sanskrit.split(' ').first,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  mantra.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${mantra.sanskrit}"',
                            style: const TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('Meaning: ${mantra.meaning}'),
                          const SizedBox(height: 5),
                          Text('Benefits: ${mantra.benefits}'),
                          const SizedBox(height: 5),
                          Text(
                            'Recommended: ${mantra.recommendedCount} times',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: Colors.blue.shade700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBpInputDialog() {
    final bpController = TextEditingController();
    if (_bloodPressure != "N/A") {
      bpController.text = _bloodPressure.replaceAll(' mmHg', '');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Blood Pressure'),
        content: TextField(
          controller: bpController,
          decoration: const InputDecoration(
            hintText: 'e.g., 120/80',
            labelText: 'Systolic/Diastolic (mmHg)',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: false, signed: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              String input = bpController.text.trim();
              if (input.contains('/') && input.split('/').length == 2) {
                List<String> parts = input.split('/');
                if (int.tryParse(parts[0]) != null && int.tryParse(parts[1]) != null) {
                  String formattedBp = '$input mmHg';
                  final prefs = await SharedPreferences.getInstance();
                  setState(() {
                    _bloodPressure = formattedBp;
                  });
                  await prefs.setString(_bpKey, formattedBp);
                  _calculateWellnessScore();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('BP recorded: $formattedBp')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid numbers (e.g., 120/80)')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please use format Systolic/Diastolic (e.g., 120/80)')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- Updated Health Metrics List (Wellness Score Removed) ---
  List<HealthMetric> get healthMetrics => [
        HealthMetric(
          "Daily Steps",
          _stepCount >= 1000 ? "${(_stepCount / 1000).toStringAsFixed(1)}K" : "$_stepCount",
          Icons.directions_walk,
          Colors.blue,
          onTap: () => _showStepsDialog(),
        ),
        HealthMetric(
          "Meditation",
          "${_meditationMinutes}min",
          Icons.psychology,
          Colors.purple,
          onTap: _addMeditationTime,
        ),
        HealthMetric(
          "Water Intake",
          "$_waterIntake/8",
          Icons.water_drop,
          Colors.cyan,
          onTap: _addWaterIntake,
        ),
        HealthMetric(
          "BP",
          _bloodPressure,
          Icons.monitor_heart,
          Colors.redAccent,
          onTap: _showBpInputDialog,
        ),
      ];

  void _showStepsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('👟', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Daily Steps'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Today: $_stepCount steps',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (_stepCount / 10000).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                  _stepCount >= 10000 ? Colors.green : Colors.blue),
            ),
            const SizedBox(height: 10),
            Text(
              _stepCount >= 10000
                  ? '🎉 Goal achieved!'
                  : 'Goal: 10,000 steps (${10000 - _stepCount} remaining)',
              style: TextStyle(
                color: _stepCount >= 10000 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.blue.shade700)),
          ),
        ],
      ),
    );
  }

  void _startQuoteRotation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % quotes.length;
        });
        _startQuoteRotation();
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _cityCtrl.dispose();
    _pageController.dispose();
    _stepCountStream?.cancel();
    super.dispose();
  }

  // --- Fetch Initial Location and Weather ---
  Future<void> _fetchInitialLocationAndWeather() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, we can't continue. Default to Hyderabad.
          print('Location permissions denied.');
          setState(() {
            _city = 'Hyderabad'; // Fallback city
          });
          _fetchWeather(); // Fetch weather for fallback city
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
         // Permissions are permanently denied, we can't request permissions. Default to Hyderabad.
         print('Location permissions permanently denied.');
          setState(() {
            _city = 'Hyderabad'; // Fallback city
          });
          _fetchWeather(); // Fetch weather for fallback city
         return;
      }

      // Get current position (network location is usually sufficient and faster)
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);

      // Reverse geocode to get place name
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Try to get the locality (city), fall back to administrative area (state/country)
        String? cityName = place.locality ?? place.administrativeArea ?? place.country;
        if (cityName != null && cityName.isNotEmpty) {
          setState(() {
            _city = cityName;
          });
          print("Detected location: $_city");
        } else {
          // If we can't get a good name, use coordinates or fallback
           print("Could not determine city name from placemarks.");
           setState(() {
            _city = 'Hyderabad'; // Fallback city if name is empty
          });
        }
      } else {
         print("No placemarks found for coordinates.");
         setState(() {
            _city = 'Hyderabad'; // Fallback city if no placemarks
          });
      }
    } catch (e) {
      print("Error getting location: $e");
      // On error, default to a city
       setState(() {
            _city = 'Hyderabad'; // Fallback city on error
       });
    } finally {
       // Fetch weather for the determined or fallback city
       _fetchWeather();
    }
  }


  // --- Fetch Weather using OpenWeatherMap API ---
  Future<void> _fetchWeather() async {
    if (_openWeatherMapApiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
      print('ERROR: OpenWeatherMap API key not set!');
      setState(() {
        _temp = null;
        _cond = null;
        _weatherTip = 'API key not configured.';
      });
      return;
    }

    if (_city.isEmpty || _city == 'Detecting...') {
      print('City name is empty or still detecting.');
       setState(() {
        _temp = null;
        _cond = null;
        _weatherTip = 'Detecting location...';
      });
      return;
    }

    setState(() {
      // Show loading while fetching
      _temp = null;
      _cond = null;
      _weatherTip = 'Loading weather...';
    });

    try {
      // OpenWeatherMap API call by city name
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$_city&appid=$_openWeatherMapApiKey&units=metric');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final double? temperature = data['main']['temp']?.toDouble();
        final String? condition = data['weather'][0]['main'] as String?;
        final String? description = data['weather'][0]['description'] as String?;

        String displayCondition = condition ?? description?.toUpperCase() ?? 'Unknown';

        setState(() {
          _temp = temperature;
          _cond = displayCondition;
          _weatherTip = getWeatherBasedTip(displayCondition, temperature);
        });
      } else if (response.statusCode == 404) {
         print('City not found: $_city');
         setState(() {
            _temp = null;
            _cond = null;
            _weatherTip = 'City not found. Please check the name.';
          });
      } else {
        print('Failed to load weather data. Status: ${response.statusCode}');
        setState(() {
          _temp = null;
          _cond = null;
          _weatherTip = 'Could not load weather. Try again.';
        });
      }
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() {
        _temp = null;
        _cond = null;
        _weatherTip = 'Network error. Check connection.';
      });
    }
  }


  void _changeCity() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_city, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('Change City'),
          ],
        ),
        content: TextField(
          controller: _cityCtrl,
          decoration: InputDecoration(
            hintText: 'e.g. Chennai',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.green.shade700, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_cityCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _city = _cityCtrl.text.trim();
                });
                _fetchWeather(); // Fetch weather for the new city
                _cityCtrl.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(FeatureItem item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailScreen(topic: item.contentType, title: item.title),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🌿', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            const Text(
              'AyurBloom',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
          ),
        ],
      ),
      body: _fadeAnimation != null
          ? FadeTransition(
              opacity: _fadeAnimation!,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Container(),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -50),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: _changeCity,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.cloud, color: Colors.blue, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _city,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _temp != null
                                                    ? '${_temp!.round()}°C · $_cond'
                                                    : _weatherTip ?? 'Loading...', // Show tip or loading
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.refresh, color: Colors.green.shade700),
                                        onPressed: _fetchWeather, // Refreshes current city weather
                                      ),
                                    ),
                                  ],
                                ),
                                if (_weatherTip != null && (_temp == null || _cond == null)) ...[
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('💡', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _weatherTip!,
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Health Metrics Row (Wellness Score Removed)
                          Container(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: healthMetrics.length,
                              itemBuilder: (context, index) {
                                final metric = healthMetrics[index];
                                return GestureDetector(
                                  onTap: metric.onTap,
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: metric.color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(metric.icon, color: metric.color, size: 20),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          metric.value,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          metric.title,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              key: ValueKey(_currentQuoteIndex),
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange.shade300, Colors.orange.shade400],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Text('🧘', style: TextStyle(fontSize: 24)),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Quote of the Day',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          quotes[_currentQuoteIndex],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Explore Natural Healing',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to all categories
                            },
                            child: Text('See All', style: TextStyle(color: Colors.green.shade700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: features.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemBuilder: (_, index) {
                          final feature = features[index];
                          return GestureDetector(
                            onTap: () => _navigateToDetails(feature),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: feature.color.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(feature.imageUrl),
                                          fit: BoxFit.cover,
                                          colorFilter: ColorFilter.mode(
                                            Colors.black.withOpacity(0.4),
                                            BlendMode.darken,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            feature.color.withOpacity(0.8),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                feature.icon,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              feature.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              feature.description,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.favorite_border, color: Colors.white, size: 18),
                                          onPressed: () {
                                            // Add to favorites
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  'Health Remedies',
                                  Icons.smart_toy,
                                  Colors.purple,
                                  () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AskDoubtScreen()));
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionCard(
                                  'Pharmacy',
                                  Icons.medical_services,
                                  Colors.teal,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MedicalTreatmentScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  'Meditation Timer',
                                  Icons.timer,
                                  Colors.indigo,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MeditationTimerScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionCard(
                                  'Health Journal',
                                  Icons.book,
                                  Colors.brown,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const HealthJournalScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.purple.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Today\'s Recommendations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          _buildRecommendationItem('🌅', 'Start your day with 5 minutes of deep breathing'),
                          _buildRecommendationItem('🥗', 'Try a healthy Ayurvedic breakfast with warm spices'),
                          _buildRecommendationItem('🚶', 'Take a 10-minute mindful walk in nature'),
                          _buildRecommendationItem('💤', 'Wind down with chamomile tea before bed'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: 0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.green.shade700,
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              if (index == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AskDoubtScreen()));
              } else if (index == 2) {
                // Analytics - Placeholder
                print("Analytics tapped");
              } else if (index == 3) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.smart_toy_rounded),
                label: 'AnciRemedies',
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}