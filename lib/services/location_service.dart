import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
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
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
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
      
      // Debug: Print all available placemark data
      for (int i = 0; i < placemarks.length && i < 3; i++) {
        final place = placemarks[i];
        print('Placemark $i:');
        print('  name: ${place.name}');
        print('  street: ${place.street}');
        print('  thoroughfare: ${place.thoroughfare}');
        print('  subThoroughfare: ${place.subThoroughfare}');
        print('  locality: ${place.locality}');
        print('  subLocality: ${place.subLocality}');
        print('  administrativeArea: ${place.administrativeArea}');
        print('  subAdministrativeArea: ${place.subAdministrativeArea}');
        print('  postalCode: ${place.postalCode}');
        print('  country: ${place.country}');
      }
      
      if (placemarks.isNotEmpty) {
        // Try to find the most detailed placemark
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
        
        // Add street number
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          addressParts.add(place.subThoroughfare!);
        }
        
        // Get location name (prioritize name over thoroughfare)
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
        
        // Get area (subLocality or locality)
        String? area;
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          area = place.subLocality;
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          area = place.locality;
        }
        
        // Format as "locationName, area"
        if (locationName != null && area != null) {
          addressParts = [locationName, area];
        } else if (locationName != null) {
          addressParts = [locationName];
        } else if (area != null) {
          addressParts = [area];
        }
        
        String result = addressParts.isNotEmpty ? addressParts.join(', ') : 'Unknown Location';
        print('Final address: $result');
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
        
        // Return just locality for short display
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
  
  static Future<List<String>> getLocationSuggestions(String query) async {
    try {
      final String url = 'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json'
          '&addressdetails=1'
          '&limit=8';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'HangBuddy App'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        
        return data
            .map((item) => item['display_name'] as String)
            .where((name) => !_isUnwantedLocation(name))
            .map((name) => _cleanLocationName(name))
            .take(8)
            .toList();
      }
    } catch (e) {
      print('Error getting location suggestions: $e');
    }
    
    return [];
  }
  
  static String _cleanLocationName(String name) {
    final parts = name.split(', ');
    if (parts.length > 3) {
      return '${parts[0]}, ${parts[1]}, ${parts[2]}';
    }
    return name;
  }
  
  static bool _isUnwantedLocation(String description) {
    final unwantedKeywords = [
      'ground floor', 'room', 'floor', 'apartment', 'flat',
      'building', 'tower', 'block', 'wing', 'unit'
    ];
    
    return unwantedKeywords.any((keyword) => 
        description.toLowerCase().contains(keyword));
  }
}