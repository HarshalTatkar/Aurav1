import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models.dart';

class EnvironmentService {
  final Dio _dio = Dio();

  Future<EnvironmentData> fetchEnvironmentData() async {
    try {
      // 1. Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return EnvironmentData(
          temperature: 28.0, humidity: 50.0, pm25: 18.0, pm10: 35.0,
          fetchedAt: DateTime.now(),
          locationName: 'Error: Location service off', isReal: false,
        );
      }

      // 2. Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return EnvironmentData(
            temperature: 28.0, humidity: 50.0, pm25: 18.0, pm10: 35.0,
            fetchedAt: DateTime.now(),
            locationName: 'Error: Location denied', isReal: false,
          );
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return EnvironmentData(
          temperature: 28.0, humidity: 50.0, pm25: 18.0, pm10: 35.0,
          fetchedAt: DateTime.now(),
          locationName: 'Error: Location blocked', isReal: false,
        );
      }

      // 3. Get position — Future.timeout() works on all platforms including web
      late double lat, lon;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high, // MUST be high for Emulator GPS mock location
        ).timeout(const Duration(seconds: 15));
        lat = position.latitude;
        lon = position.longitude;
      } catch (e) {
        // Fall back to last known on timeout
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) {
          return EnvironmentData(
            temperature: 28.0, humidity: 50.0, pm25: 18.0, pm10: 35.0,
            fetchedAt: DateTime.now(),
            locationName: 'Error: ${e.toString().split('\n').first}', isReal: false,
          );
        }
        lat = last.latitude;
        lon = last.longitude;
      }

      // 4. Fetch Weather & Air Quality in parallel
      final results = await Future.wait([
        _dio.get(
          'https://api.open-meteo.com/v1/forecast',
          queryParameters: {
            'latitude': lat,
            'longitude': lon,
            'current': 'temperature_2m,relative_humidity_2m',
          },
        ),
        _dio.get(
          'https://air-quality-api.open-meteo.com/v1/air-quality',
          queryParameters: {
            'latitude': lat,
            'longitude': lon,
            'current': 'pm2_5,pm10',
          },
        ),
      ]);

      final weatherData = results[0].data['current'];
      final airData = results[1].data['current'];

      // 5. Set location name to coordinates
      String locationName =
          '${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°';

      return EnvironmentData(
        temperature: (weatherData['temperature_2m'] as num).toDouble(),
        humidity: (weatherData['relative_humidity_2m'] as num).toDouble(),
        pm25: (airData['pm2_5'] as num).toDouble(),
        pm10: (airData['pm10'] as num).toDouble(),
        fetchedAt: DateTime.now(),
        locationName: locationName,
        isReal: true,
      );
    } catch (e) {
      return EnvironmentData(
        temperature: 28.0, humidity: 50.0, pm25: 18.0, pm10: 35.0,
        fetchedAt: DateTime.now(),
        locationName: 'Error: ${e.toString().split('\n').first}',
        isReal: false,
      );
    }
  }
}
