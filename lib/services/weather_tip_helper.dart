class WeatherTipHelper {
  static String getTip(String cond) {
    switch (cond.toLowerCase()) {
      case 'clear': return '☀️ Sunny! Stay hydrated with coconut water.';
      case 'rain': case 'drizzle': return '🌧️ Rainy day! Try immune-boosting turmeric milk.';
      case 'snow': return '❄️ Cold outside! Practice warm-up yoga and drink herbal tea.';
      case 'clouds': return '⛅ Cloudy skies—perfect for light pranayama.';
      case 'mist': case 'fog': return '🌫️ Air is hazy. Stay indoors and do steam therapy.';
      default: return 'Enjoy your day and listen to your body!';
    }
  }
}
