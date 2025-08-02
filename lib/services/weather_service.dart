import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather_tip_helper.dart';

const OPEN_WEATHER_API_KEY = '303ceceead7788eb403c5458bae60fe7';

class WeatherService {
  static Future<Map<String, dynamic>?> fetchWeather(String city) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$OPEN_WEATHER_API_KEY&units=metric');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      final temp = (json['main']['temp'] as num).toDouble();
      final cond = json['weather'][0]['main'] as String;
      return {
        'city': json['name'],
        'temp': temp,
        'cond': cond,
        'tip': WeatherTipHelper.getTip(cond),
      };
    }
    return null;
  }
}
