import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  // Cache user position so we don't re-fetch GPS on every keystroke
  static Position? _cachedPosition;
  static DateTime? _positionCacheTime;
  static const _positionCacheDuration = Duration(minutes: 5);

  // Session token for Google Places — groups autocomplete calls into 1 billing unit
  static String _sessionToken = _generateSessionToken();

  /// Generate a random UUID-like session token
  static String _generateSessionToken() {
    final random = Random();
    return List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  /// Call this when user selects a location or clears the field to start a new billing session
  static void resetSessionToken() {
    _sessionToken = _generateSessionToken();
  }

  static Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // Cache the position
      _cachedPosition = position;
      _positionCacheTime = DateTime.now();
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Returns cached position if fresh enough, otherwise fetches new one
  static Future<Position?> _getCachedOrCurrentPosition() async {
    if (_cachedPosition != null &&
        _positionCacheTime != null &&
        DateTime.now().difference(_positionCacheTime!) < _positionCacheDuration) {
      return _cachedPosition;
    }
    return await getCurrentPosition();
  }

  static Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
    } catch (e) {
      print('Error getting coordinates: $e');
    }
    return null;
  }

  static double calculateDistance(
    double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark? bestPlace;
        for (final place in placemarks) {
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            bestPlace = place;
            break;
          }
          if (place.name != null && place.name!.isNotEmpty && 
              !(place.name!.contains('+') && RegExp(r'^[A-Z0-9+]+$').hasMatch(place.name!.toUpperCase()))) {
            bestPlace = place;
          }
        }
        
        final place = bestPlace ?? placemarks.first;
        List<String> addressParts = [];
        
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          addressParts.add(place.subThoroughfare!);
        }
        
        String? locationName;
        if (place.name != null && place.name!.isNotEmpty) {
          bool isNamePlusCode = place.name!.contains('+') && 
              RegExp(r'^[A-Z0-9+]+$').hasMatch(place.name!.toUpperCase());
          if (!isNamePlusCode) {
            locationName = place.name;
          }
        }
        if (locationName == null && place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          locationName = place.thoroughfare;
        }
        
        String? area;
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          area = place.subLocality;
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          area = place.locality;
        }
        
        if (locationName != null && area != null) {
          addressParts = [locationName, area];
        } else if (locationName != null) {
          addressParts = [locationName];
        } else if (area != null) {
          addressParts = [area];
        }
        
        String result = addressParts.isNotEmpty ? addressParts.join(', ') : 'Unknown Location';
        return result;
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return null;
  }
  
  static Future<String?> getShortAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          return place.locality!;
        } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          return place.subAdministrativeArea!;
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          return place.administrativeArea!;
        }
      }
    } catch (e) {
      print('Error getting short address: $e');
    }
    return null;
  }
  
  /// Uses Google Places Autocomplete API for fast, fuzzy location search.
  /// Requires minimum 3 characters to avoid wasting API calls.
  /// Uses session tokens to bundle multiple keystrokes into 1 billing unit.
  static Future<List<String>> getLocationSuggestions(String query) async {
    // Don't search for very short queries — saves API calls
    if (query.trim().length < 3) return [];

    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('Google Places API key not found in .env');
        return [];
      }

      final position = _cachedPosition;

      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$apiKey'
          '&types=establishment|geocode'
          '&sessiontoken=$_sessionToken';

      // Bias results toward user's location if available
      if (position != null) {
        url += '&location=${position.latitude},${position.longitude}'
            '&radius=50000';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map<String>((p) => _cleanPlaceDescription(p['description'] as String))
              .take(8)
              .toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          print('Google Places API error: ${data['status']} - ${data['error_message'] ?? ''}');
        }
      }
    } catch (e) {
      print('Error getting location suggestions: $e');
    }
    
    return [];
  }

  /// Strips state and country (e.g. "Kerala, India") from place descriptions
  static String _cleanPlaceDescription(String description) {
    final parts = description.split(', ');
    if (parts.length <= 2) return description;
    return parts.sublist(0, parts.length - 2).join(', ');
  }

  /// Get Place Details (lat/lng) from a Google Places prediction
  static Future<Map<String, double>?> getPlaceCoordinates(String placeDescription) async {
    try {
      return await getCoordinatesFromAddress(placeDescription);
    } catch (e) {
      print('Error getting place coordinates: $e');
      return null;
    }
  }
}