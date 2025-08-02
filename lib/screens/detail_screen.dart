import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  final String topic;
  final String title;

  const DetailScreen({super.key, required this.topic, required this.title});

  @override
  State<DetailScreen> createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Set<int> completedTips = {};

  @override
  void initState() {
    super.initState();
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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getTipsAndMotivation(String topic) {
    switch (topic) {
      case "yoga":
        return {
          "hero_text": "🧘‍♀️ Transform Your Life with Yoga",
          "motivation": "Just 20 minutes daily can reduce stress by 68% and improve flexibility within 2 weeks!",
          "tips": [
            "🌅 Start with Sun Salutation (Surya Namaskar) - energizes your entire day",
            "⏰ Practice daily for just 20 mins - consistency beats intensity",
            "🏠 Create a sacred space with yoga mat and calming music",
            "🫁 Master breathing techniques - the foundation of all poses",
            "📱 Follow guided sessions until you build confidence",
            "🌙 Try evening yoga for better sleep quality",
            "💪 Hold each pose for 30 seconds minimum for strength building",
            "🧘‍♂️ End with 5 minutes of meditation for mental clarity"
          ],
          "benefits": ["Reduces stress by 68%", "Improves flexibility in 2 weeks", "Better sleep quality", "Increased strength & balance"]
        };
      
      case "ayurveda":
        return {
          "hero_text": "🌿 Ancient Wisdom for Modern Wellness",
          "motivation": "5000-year-old science proven to boost immunity and energy levels naturally!",
          "tips": [
            "🧡 Add turmeric to warm milk - nature's most powerful anti-inflammatory",
            "💧 Drink warm water throughout the day - aids digestion and detox",
            "🤲 Abhyanga: Daily oil massage - improves circulation and skin health",
            "⚖️ Follow your dosha routine - personalized wellness approach",
            "🌙 Avoid cold foods after sunset - supports digestive fire",
            "🌱 Start day with Triphala - the ultimate digestive cleanser",
            "🍯 Take Ashwagandha with honey - reduces cortisol by 30%",
            "🧘‍♀️ Practice Pranayama breathing - balances your nervous system"
          ],
          "benefits": ["Boosts immunity naturally", "Reduces inflammation", "Better digestion", "Balanced energy levels"]
        };
      
      case "home_remedies":
        return {
          "hero_text": "🏠 Nature's Pharmacy in Your Kitchen",
          "motivation": "Simple ingredients can be more effective than expensive medicines - start healing today!",
          "tips": [
            "🍯🍋 Honey + Lemon tea - soothes throat and fights infections instantly",
            "🫚 Fresh ginger tea - reduces nausea and aids digestion within minutes",
            "🌿 Tulsi leaves daily - builds immunity stronger than vitamin C",
            "🦷 Clove oil on cotton - immediate toothache relief",
            "🥥 Coconut oil massage - transforms dry skin in 3 days",
            "🧄 Raw garlic clove - natural antibiotic for cold prevention",
            "🧂 Salt water gargle - kills bacteria and heals sore throat",
            "🌸 Rose water spray - instant skin refresher and mood booster"
          ],
          "benefits": ["Instant relief", "No side effects", "Cost-effective", "Always available at home"]
        };
      
      case "naturopathy":
        return {
          "hero_text": "⚡ Harness Nature's Healing Power",
          "motivation": "Your body has incredible self-healing abilities - activate them naturally!",
          "tips": [
            "🍋💧 Lemon water first thing - detoxifies and alkalizes your body",
            "☀️ 30 minutes sunlight daily - natural vitamin D and serotonin boost",
            "🧊 Cold packs for inflammation - natural pain relief without drugs",
            "🦶 Barefoot earth connection - reduces stress hormones by 23%",
            "🚿 Contrast showers - improves circulation and immunity",
            "🥒 Fresh vegetable juices - floods body with living enzymes",
            "🌬️ Deep breathing exercises - oxygenates every cell",
            "💆‍♀️ Clay face masks - natural skin detox and glow"
          ],
          "benefits": ["Zero side effects", "Strengthens natural immunity", "Improves circulation", "Mental clarity"]
        };
      
      case "acupuncture":
        return {
          "hero_text": "🎯 Precision Healing Through Ancient Points",
          "motivation": "WHO recognizes acupuncture for 100+ conditions - experience the transformation!",
          "tips": [
            "💊 Effective for chronic pain - 85% success rate for back pain",
            "👨‍⚕️ Choose certified practitioners only - safety and results guaranteed",
            "🍽️ Light meal 2 hours before - optimal energy flow during treatment",
            "⚡ Expect tingling sensation - sign of energy blockage clearing",
            "💧 Hydrate well after session - helps flush toxins released",
            "😴 Schedule evening appointments - promotes deep healing sleep",
            "📅 Weekly sessions for 6 weeks - sustainable long-term results",
            "🧘‍♀️ Combine with meditation - amplifies healing benefits"
          ],
          "benefits": ["85% success for pain relief", "No drug side effects", "Treats root causes", "Improves energy flow"]
        };
      
      case "diet":
        return {
          "hero_text": "🥗 Food as Medicine Revolution",
          "motivation": "Transform your health in 30 days - every meal is a chance to heal or harm!",
          "tips": [
            "🍎 Seasonal fruits & vegetables - maximum nutrition and natural taste",
            "🚫 Eliminate processed sugars - energy levels stabilize in 1 week",
            "🍵 Herbal teas daily - chamomile, green tea boost metabolism by 12%",
            "🔥 Warm, cooked meals - easier digestion and nutrient absorption",
            "🐌 Chew 32 times per bite - improves digestion and satisfaction",
            "🌈 Eat the rainbow daily - ensures complete nutrient spectrum",
            "💧 Drink before meals - not during, aids proper digestion",
            "🕕 Early dinner by 7 PM - improves sleep and weight management"
          ],
          "benefits": ["Stable energy all day", "Natural weight management", "Better digestion", "Glowing skin"]
        };
      
      default:
        return {
          "hero_text": "🌟 Your Wellness Journey Starts Here",
          "motivation": "Every small step towards natural health creates lasting transformation!",
          "tips": ["Choose a category above to discover powerful natural remedies"],
          "benefits": []
        };
    }
  }

  Map<String, List<Map<String, String>>> getYouTubeContent(String topic) {
    switch (topic) {
      case "yoga":
        return {
          "videos": [
            {"title": "20-Min Morning Yoga Flow - Energize Your Day", "url": "https://www.youtube.com/watch?v=v7AYKMP6rOE", "duration": "20 mins"},
            {"title": "Yoga for Complete Beginners - Start Here!", "url": "https://www.youtube.com/watch?v=--jhKVdZOJM", "duration": "30 mins"},
            {"title": "Evening Yoga for Deep Sleep", "url": "https://www.youtube.com/watch?v=Av7yZ_2yl2A", "duration": "20 mins"},
            {"title": "Power Yoga for Strength Building", "url": "https://www.youtube.com/watch?v=5h-9pqWIkzg", "duration": "29 mins"},
            {"title": "Sun Salutation Step by Step", "url": "https://www.youtube.com/watch?v=UPszTB6UzaA", "duration": "9 mins"}
          ]
        };
      
      case "ayurveda":
        return {
          "videos": [
            {"title": "🌿 Complete Ayurveda Guide for Beginners", "url": "https://www.youtube.com/watch?v=n3F3vGJi8bs", "duration": "35 mins"},
            {"title": "⚖️ Discover Your Dosha Type", "url": "https://www.youtube.com/watch?v=icO7sQ6EEVc", "duration": "20 mins"},
            {"title": "🤲 Self-Massage (Abhyanga) Tutorial", "url": "https://www.youtube.com/watch?v=baa64z0MSlo", "duration": "11 mins"},
            {"title": "🧡 Golden Milk Recipe & Benefits", "url": "https://www.youtube.com/watch?v=X6KFQz-cQK8", "duration": "3 mins"},
            {"title": "🫁 Pranayama Breathing Techniques", "url": "https://www.youtube.com/watch?v=blbv5UTBCGg", "duration": "10 mins"}
          ]
        };
      
      case "home_remedies":
        return {
          "videos": [
            {"title": "🏠 15 Kitchen Remedies That Actually Work", "url": "https://www.youtube.com/watch?v=DEuXMWLEu7A", "duration": "22 mins"},
            {"title": "🍯 Honey Remedies for Common Problems", "url": "https://www.youtube.com/watch?v=G70OzZBjWgc", "duration": "16 mins"},
            {"title": "🫚 Ginger: Nature's Medicine Cabinet", "url": "https://www.youtube.com/watch?v=C2PbRf3IhZQ", "duration": "10 mins"},
            {"title": "🌿 Tulsi: The Holy Basil Miracle", "url": "https://www.youtube.com/watch?v=ms_sVoyQbVs", "duration": "21 mins"},
            {"title": "🧄 Garlic Remedies for Immunity", "url": "https://www.youtube.com/watch?v=TkPnZ1Or0MU", "duration": "1 mins"}
          ]
        };
      
      case "naturopathy":
        return {
          "videos": [
            {"title": "⚡ Naturopathy: Complete Healing System", "url": "https://www.youtube.com/watch?v=KMtoA1Ijw1A", "duration": "28 mins"},
            {"title": "💧 Hydrotherapy at Home", "url": "https://www.youtube.com/watch?v=OIyzeqCfM0c", "duration": "20 mins"},
            {"title": "☀️ Sunlight Therapy Benefits", "url": "https://www.youtube.com/watch?v=nk0atIkDZTk", "duration": "7 mins"},
            {"title": "🦶 Earthing: Barefoot Healing", "url": "https://www.youtube.com/watch?v=8Rsb7IB21iM", "duration": "6 mins"},
            {"title": "🌬️ Breathing for Natural Healing", "url": "https://www.youtube.com/watch?v=JwqzGx-t23s", "duration": "35 mins"}
          ]
        };
      
      case "acupuncture":
        return {
          "videos": [
            {"title": "🎯 How Acupuncture Actually Works", "url": "https://www.youtube.com/watch?v=-40MeW7s_nQ", "duration": "12 mins"},
            {"title": "💆‍♀️ Acupressure Points for Daily Use", "url": "https://www.youtube.com/watch?v=fHls1DrHxR8", "duration": "16 mins"},
            {"title": "🤲 Self-Acupressure for Headaches", "url": "https://www.youtube.com/watch?v=Ngq-Y1JH-QA", "duration": "8 mins"},
            {"title": "Acupuncture for Chronic Pain", "url": "https://www.youtube.com/watch?v=tROxjcBJQ_M", "duration": "1 min"},
            {"title": "🧘‍♀️ Energy Meridians Explained", "url": "https://www.youtube.com/watch?v=E1c_k_a0GjU", "duration": "3 mins"}
          ]
        };
      
      case "diet":
        return {
          "videos": [
            {"title": "🥗 Anti-Inflammatory Foods That Heal", "url": "https://www.youtube.com/watch?v=uBoQJkNEx-M", "duration": "18 mins"},
            {"title": "🌈 Eating the Rainbow for Health", "url": "https://www.youtube.com/watch?v=XBvMt45d66Q", "duration": "22 mins"},
            {"title": "🍵 Healing Herbal Teas Guide", "url": "https://www.youtube.com/watch?v=1cVJwxN6abs", "duration": "9 mins"},
            {"title": "⏰ Intermittent Fasting Basics", "url": "https://www.youtube.com/watch?v=jszrZ_BF7xQ", "duration": "11 mins"},
            {"title": "🥑 Healthy Fats That Heal Your Body", "url": "https://www.youtube.com/watch?app=desktop&v=mACg0l9EzDk", "duration": "6 mins"}
          ]
        };
      
      default:
        return {"videos": []};
    }
  }

  Color _getTopicColor(String topic) {
    switch (topic) {
      case "yoga": return Colors.purple.shade400;
      case "ayurveda": return Colors.orange.shade400;
      case "home_remedies": return Colors.green.shade400;
      case "naturopathy": return Colors.blue.shade400;
      case "acupuncture": return Colors.red.shade400;
      case "diet": return Colors.teal.shade400;
      default: return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = getTipsAndMotivation(widget.topic);
    final videoData = getYouTubeContent(widget.topic);
    final topicColor = _getTopicColor(widget.topic);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Animated App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: topicColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black26)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [topicColor, topicColor.withOpacity(0.7)],
                  ),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          data['hero_text'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Motivation Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [topicColor.withOpacity(0.1), topicColor.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: topicColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.favorite, color: Colors.red, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              data['motivation'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (data['benefits'].isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: data['benefits'].map<Widget>((benefit) => 
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: topicColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      benefit,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: topicColor.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Tips Section
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: topicColor, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            "Start Your Journey Today",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: topicColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Interactive Tips List
                      ...data['tips'].asMap().entries.map((entry) {
                        int index = entry.key;
                        String tip = entry.value;
                        bool isCompleted = completedTips.contains(index);
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isCompleted ? topicColor.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompleted ? topicColor : Colors.grey.shade300,
                              width: isCompleted ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.05),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isCompleted) {
                                    completedTips.remove(index);
                                  } else {
                                    completedTips.add(index);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isCompleted ? topicColor : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCompleted ? topicColor : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isCompleted 
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                                    : null,
                              ),
                            ),
                            title: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isCompleted ? topicColor : Colors.grey.shade700,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                height: 1.3,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: topicColor.withOpacity(0.6),
                            ),
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 30),
                      
                      // Progress Indicator
                      if (completedTips.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [topicColor.withOpacity(0.1), topicColor.withOpacity(0.05)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "🎉 Amazing Progress!",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: topicColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "You've completed ${completedTips.length} out of ${data['tips'].length} tips!",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: completedTips.length / data['tips'].length,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(topicColor),
                                minHeight: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                      
                      // Videos Section
                      if (videoData['videos']!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.play_circle, color: Colors.red, size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              "Watch & Transform",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ...videoData['videos']!.map((video) => GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse(video['url']!),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video['title']!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            video['duration']!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )).toList(),
                      ],
                      
                      // Call to Action
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [topicColor, topicColor.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 8),
                              blurRadius: 20,
                              color: topicColor.withOpacity(0.3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "🚀 Ready to Transform?",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Start with just ONE tip today. Small steps lead to extraordinary results!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                // Could navigate to a journal or tracking screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("🎉 Your healing journey has begun!"),
                                    backgroundColor: topicColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: topicColor,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Start My Journey",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}