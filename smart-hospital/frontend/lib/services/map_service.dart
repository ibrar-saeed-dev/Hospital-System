import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapService {
  MapService._();

  /// Launch Google Maps with turn-by-turn driving directions to destination
  static Future<bool> openInGoogleMaps(
    double lat,
    double lng, [
    String? name,
  ]) async {
    final destination = '$lat,$lng';
    final urlString =
        'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving';
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      return false;
    }
  }

  /// Launch Google Maps searching for a specific coordinate location
  static Future<bool> openLocationInGoogleMaps(double lat, double lng) async {
    final urlString = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      return false;
    }
  }

  /// Retrieve current user GPS coordinates using geolocator with friendly error handling
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied by the user.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable them in your device settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}
