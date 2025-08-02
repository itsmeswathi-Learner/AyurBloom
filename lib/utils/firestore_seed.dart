import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirestoreSeeder.seedData();
}

class FirestoreSeeder {
  static final List<Map<String, dynamic>> remedies = [
    {
      "title": "Triphala for Constipation",
      "keywords": ["constipation", "digestion", "vata"],
      "advice":
          "Mix 1 tsp Triphala powder in warm water and take before bedtime. Balances Vata and improves bowel movement. Not for pregnant women.",
      "type": "ayurveda",
      "image_url": "https://www.ayurtimes.com/wp-content/uploads/Triphala.jpg"
    },
    {
      "title": "Anulom Vilom Pranayama for Stress",
      "keywords": ["stress", "anxiety", "pranayama", "calm"],
      "advice":
          "Sit in a quiet space. Use right thumb to close right nostril, inhale through left. Then close left nostril and exhale through right. Repeat 5-10 min daily.",
      "type": "yoga",
      "image_url": "https://i.ytimg.com/vi/P9z3OO0_qxs/maxresdefault.jpg"
    },
    {
      "title": "Ginger Tea for Cold & Flu",
      "keywords": ["cold", "flu", "immunity", "cough"],
      "advice":
          "Boil crushed ginger in water with tulsi and pepper. Add honey. Drink warm. Boosts immunity and clears throat.",
      "type": "home_remedy",
      "image_url": "https://www.ayurveda-for-life.com/wp-content/uploads/2017/07/ginger_tea.jpg"
    },
    {
      "title": "Turmeric Milk for Body Pains",
      "keywords": ["body pain", "inflammation", "recovery"],
      "advice":
          "Boil 1 glass milk with 1/2 tsp turmeric. Drink at night. Reduces inflammation and joint pain. Avoid for those with milk allergy.",
      "type": "ayurveda",
      "image_url": "https://cdn.cdnparenting.com/articles/2019/03/19155014/Golden-Milk-or-Turmeric-Milk-Benefits.jpg"
    },
    {
      "title": "Surya Namaskar for Full Body Health",
      "keywords": ["fitness", "health", "exercise", "surya namaskar"],
      "advice":
          "Perform 12 poses of Surya Namaskar every morning. Enhances metabolism, circulation, and mental clarity.",
      "type": "yoga",
      "image_url": "https://www.yogajournal.com/.image/t_share/MTQ2MTgwOTgyNzI4NjM5NDI1/surya-namaskar.jpg"
    },
    {
      "title": "Fenugreek Seeds for Hair Fall",
      "keywords": ["hair fall", "scalp", "dandruff"],
      "advice":
          "Soak methi overnight. Make paste and apply to scalp. Wash after 30 mins. Strengthens roots and stops hair fall.",
      "type": "home_remedy",
      "image_url": "https://www.femina.in/imported/images/femina/beauty/2020/march/fenugreek-for-hair.jpg"
    },
    {
      "title": "Ashwagandha for Stress & Immunity",
      "keywords": ["stress", "energy", "sleep", "immunity"],
      "advice":
          "Take 500mg Ashwagandha capsule once daily after food. Boosts stamina, calms nerves. Avoid in pregnancy.",
      "type": "ayurveda",
      "image_url": "https://static.toiimg.com/photo/msid-71804685/71804685.jpg"
    },
    {
      "title": "Butterfly Pose for Menstrual Cramps",
      "keywords": ["period pain", "menstrual", "cramps"],
      "advice":
          "Sit, join soles of feet. Flap knees gently. Practice for 5-10 mins daily to reduce cramps and balance hormones.",
      "type": "yoga",
      "image_url": "https://cdn2.stylecraze.com/wp-content/uploads/2014/11/Butterfly-Pose-Or-Baddha-Konasana.jpg"
    },
    {
      "title": "Neem Paste for Pimples",
      "keywords": ["pimples", "acne", "skin"],
      "advice":
          "Crush neem leaves into paste. Apply to pimples for 15 mins and rinse. Anti-bacterial and clears acne.",
      "type": "home_remedy",
      "image_url": "https://cdn2.stylecraze.com/wp-content/uploads/2013/05/2045_How-To-Use-Neem-For-Acne_shutterstock_372348597.jpg"
    },
    {
      "title": "Trikatu for Digestion",
      "keywords": ["digestion", "indigestion", "appetite"],
      "advice":
          "Mix equal parts black pepper, ginger, long pepper. Take 1/4 tsp with honey before meals. Stimulates appetite.",
      "type": "ayurveda",
      "image_url": "https://ayurmedinfo.com/wp-content/uploads/2013/01/Trikatu-churna.jpg"
    },
    {
      "title": "Padahastasana for Constipation",
      "keywords": ["constipation", "digestion", "flexibility"],
      "advice":
          "Stand, bend forward, try to touch toes. Hold 30 secs. Enhances bowel movement and spinal strength.",
      "type": "yoga",
      "image_url": "https://www.arhantayoga.org/wp-content/uploads/2021/06/Padahastasana-Forward-Bend-Yoga.jpg"
    },
    {
      "title": "Tulsi Tea for Immunity",
      "keywords": ["immunity", "cold", "cough"],
      "advice":
          "Boil tulsi leaves in water with ginger. Drink twice daily. Boosts immunity and clears congestion.",
      "type": "home_remedy",
      "image_url": "https://5.imimg.com/data5/YX/VR/GLADMIN-2/tulsi-tea.jpg"
    },
    {
      "title": "Nasyam for Sinus Relief",
      "keywords": ["sinus", "headache", "nasal", "kapha"],
      "advice":
          "Lie down, drop 2 drops Anu tailam in nostrils. Clears nasal blockage and enhances memory. Do under guidance.",
      "type": "naturopathy",
      "image_url": "https://ayurvedaupay.com/wp-content/uploads/2020/02/nasya-karma.jpg"
    },
    {
      "title": "Ghee in Navel for Skin Glow",
      "keywords": ["skin", "glow", "dryness"],
      "advice":
          "Apply 1 drop of ghee in belly button at night. Softens skin and improves glow. Old Ayurvedic practice.",
      "type": "home_remedy",
      "image_url": "https://assets.lybrate.com/q_auto,f_auto/imgs/product/health-wiki/diseases/ghee.jpg"
    },
    {
      "title": "Brahmi for Memory Boost",
      "keywords": ["memory", "focus", "brain", "concentration"],
      "advice":
          "Take Brahmi powder (1/4 tsp) with milk daily. Sharpens memory and calms mind.",
      "type": "ayurveda",
      "image_url": "https://www.ayurvedicindia.info/wp-content/uploads/2017/08/Brahmi-herb.jpg"
    },
    {
      "title": "Chandrabhedi Pranayama for Cooling",
      "keywords": ["heat", "cooling", "pitta", "anger"],
      "advice":
          "Inhale through left nostril, exhale through right. Practice for 5 mins daily to cool body & calm emotions.",
      "type": "yoga",
      "image_url": "https://static.wixstatic.com/media/50cbf8_3abdb94b3f8548eab7a08f30fc03d34d~mv2.jpg"
    },
    {
      "title": "Cumin Water for Digestion",
      "keywords": ["digestion", "gas", "bloating"],
      "advice":
          "Boil 1 tsp cumin seeds in water. Drink after meals. Improves digestion and reduces bloating.",
      "type": "home_remedy",
      "image_url": "https://www.momjunction.com/wp-content/uploads/2017/12/Benefits-Of-Jeera-Water-During-Pregnancy.jpg"
    },
    {
      "title": "Kapalbhati for Detoxification",
      "keywords": ["toxins", "detox", "belly fat"],
      "advice":
          "Sit straight, forcefully exhale through nose. Repeat 50 times. Removes toxins and aids fat loss.",
      "type": "yoga",
      "image_url": "https://www.artofliving.org/sites/www.artofliving.org/files/wysiwyg_imageupload/kapalbhati.jpg"
    },
    {
      "title": "Giloy Juice for Fever",
      "keywords": ["fever", "dengue", "malaria", "immunity"],
      "advice":
          "Drink 15ml Giloy juice with water daily during fever. Reduces temperature and strengthens immunity.",
      "type": "ayurveda",
      "image_url": "https://www.herzindagi.com/hindi/wp-content/uploads/2020/07/giloy-for-immunity-1200.jpg"
    },
    {
      "title": "Oil Pulling for Oral Health",
      "keywords": ["oral health", "mouth", "teeth", "bacteria"],
      "advice":
          "Swish 1 tbsp sesame or coconut oil in mouth for 10 mins. Spit out and rinse. Detoxes mouth and strengthens gums.",
      "type": "naturopathy",
      "image_url": "https://www.merakilane.com/wp-content/uploads/2020/01/OilPulling.png"
    },
  ];

  static Future<void> seedData() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (var remedy in remedies) {
      final docRef = firestore.collection("knowledge_base").doc();
      batch.set(docRef, remedy);
    }

    await batch.commit();
    print("✅ 30 Remedies uploaded to Firestore!");
  }
}
