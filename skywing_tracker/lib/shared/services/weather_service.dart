import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skywing_tracker/core/constants.dart';

class WeatherService {
  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    final key = AppConstants.weatherApiKey;
    final url =
        'https://api.weatherapi.com/v1/current.json?key=$key&q=$lat,$lon';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch weather: ${response.statusCode}');
  }
}
