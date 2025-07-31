import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'config_service.dart';

class TravelInfo {
  final String fromLocation;
  final String toLocation;
  final String duration;
  final String distance;
  final String mode; // flight, driving, etc.

  TravelInfo({
    required this.fromLocation,
    required this.toLocation,
    required this.duration,
    required this.distance,
    required this.mode,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Get user's current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check location permission
      final permission = await Permission.location.status;
      if (!permission.isGranted) {
        final result = await Permission.location.request();
        if (!result.isGranted) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Get location name from coordinates
  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.locality}, ${place.country}';
      }
    } catch (e) {
      debugPrint('Error getting location name: $e');
    }
    return 'Unknown Location';
  }

  /// Get travel information between two locations using Google Maps API
  Future<TravelInfo?> getTravelInfo(String destination) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        // Fallback to a default location if we can't get user location
        return TravelInfo(
          fromLocation: 'Your Location',
          toLocation: destination,
          duration: 'Duration unavailable',
          distance: 'Distance unavailable',
          mode: 'flight',
        );
      }

      final fromLocation = await getLocationName(
        position.latitude,
        position.longitude,
      );

      // For international destinations, we'll use flight time estimation
      if (await _isInternationalDestination(position, destination)) {
        final flightInfo = await _getFlightInfo(fromLocation, destination);
        return flightInfo;
      } else {
        // For domestic/nearby destinations, use driving directions
        final drivingInfo = await _getDrivingInfo(position, destination);
        return drivingInfo;
      }
    } catch (e) {
      debugPrint('Error getting travel info: $e');
      return null;
    }
  }

  /// Check if destination is international (simple heuristic)
  Future<bool> _isInternationalDestination(
    Position userPosition,
    String destination,
  ) async {
    // Simple check: if destination contains country name different from user's country
    try {
      final userLocation = await getLocationName(
        userPosition.latitude,
        userPosition.longitude,
      );
      final userCountry = userLocation.split(', ').last;

      // Common international destinations
      final internationalKeywords = [
        'Indonesia',
        'Thailand',
        'Japan',
        'France',
        'Italy',
        'Spain',
        'USA',
        'UK',
        'Australia',
      ];

      return internationalKeywords.any(
        (keyword) =>
            destination.toLowerCase().contains(keyword.toLowerCase()) &&
            !userCountry.toLowerCase().contains(keyword.toLowerCase()),
      );
    } catch (e) {
      return true; // Default to international if we can't determine
    }
  }

  /// Get flight information (estimated)
  Future<TravelInfo> _getFlightInfo(
    String fromLocation,
    String destination,
  ) async {
    // This is a simplified flight time estimation
    // In a real app, you'd use a flight API like Amadeus or Skyscanner

    final flightDurations = {
      'bali': {
        'india': '11hrs 5mins',
        'usa': '18hrs 30mins',
        'europe': '14hrs 20mins',
      },
      'thailand': {
        'india': '4hrs 30mins',
        'usa': '17hrs 45mins',
        'europe': '11hrs 15mins',
      },
      'japan': {
        'india': '7hrs 20mins',
        'usa': '12hrs 30mins',
        'europe': '12hrs 40mins',
      },
    };

    String duration = '10-15 hours'; // Default estimate

    for (final dest in flightDurations.keys) {
      if (destination.toLowerCase().contains(dest)) {
        for (final origin in flightDurations[dest]!.keys) {
          if (fromLocation.toLowerCase().contains(origin)) {
            duration = flightDurations[dest]![origin]!;
            break;
          }
        }
        break;
      }
    }

    return TravelInfo(
      fromLocation: fromLocation,
      toLocation: destination,
      duration: duration,
      distance: 'International flight',
      mode: 'flight',
    );
  }

  /// Get driving information using Google Maps Directions API
  Future<TravelInfo> _getDrivingInfo(
    Position userPosition,
    String destination,
  ) async {
    try {
      // Note: You'll need to add GOOGLE_MAPS_API_KEY to your .env file
      final apiKey = ConfigService.googleMapsApiKey;
      if (apiKey.isEmpty) {
        return _getEstimatedDrivingInfo(userPosition, destination);
      }

      final url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${userPosition.latitude},${userPosition.longitude}'
          '&destination=${Uri.encodeComponent(destination)}'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final duration = leg['duration']['text'];
          final distance = leg['distance']['text'];
          final fromLocation = await getLocationName(
            userPosition.latitude,
            userPosition.longitude,
          );

          return TravelInfo(
            fromLocation: fromLocation,
            toLocation: destination,
            duration: duration,
            distance: distance,
            mode: 'driving',
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting driving directions: $e');
    }

    return _getEstimatedDrivingInfo(userPosition, destination);
  }

  /// Fallback estimated driving info
  Future<TravelInfo> _getEstimatedDrivingInfo(
    Position userPosition,
    String destination,
  ) async {
    final fromLocation = await getLocationName(
      userPosition.latitude,
      userPosition.longitude,
    );

    return TravelInfo(
      fromLocation: fromLocation,
      toLocation: destination,
      duration: 'Duration unavailable',
      distance: 'Distance unavailable',
      mode: 'driving',
    );
  }

  /// Extract destination from itinerary (helper method)
  String extractDestinationFromItinerary(dynamic itinerary) {
    // Try to extract destination from itinerary title or first day activities
    if (itinerary != null) {
      final title = itinerary.title?.toString() ?? '';

      // Common destination patterns
      final destinations = [
        'Bali',
        'Thailand',
        'Japan',
        'Paris',
        'London',
        'New York',
        'Tokyo',
        'Bangkok',
        'Rome',
      ];

      for (final dest in destinations) {
        if (title.toLowerCase().contains(dest.toLowerCase())) {
          return dest;
        }
      }

      // If no common destination found, try to extract from title
      final words = title.split(' ');
      for (final word in words) {
        if (word.length > 3 && word[0].toUpperCase() == word[0]) {
          return word;
        }
      }
    }

    return 'Destination';
  }
}
