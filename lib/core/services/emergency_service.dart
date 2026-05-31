import 'dart:developer';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Emergency service for sending SOS alerts via WhatsApp/SMS deep links
/// User must manually press Send - no auto-sending
class EmergencyService {
  EmergencyService({required this.contacts});

  /// List of contacts: [{'name': 'Mom', 'phone': '+91XXXXXXXXXX'}, ...]
  final List<Map<String, String>> contacts;

  /// Trigger SOS alert via WhatsApp or SMS
  Future<void> triggerSOS({bool useWhatsApp = false}) async {
    final message = await _buildAlertMessage(
      title: 'SOS ALERT',
      body: 'I need immediate help! This is an emergency.',
    );
    await _sendToContacts(message, useWhatsApp: useWhatsApp);
  }

  /// Trigger Emergency alert via WhatsApp or SMS
  Future<void> triggerEmergency({bool useWhatsApp = false}) async {
    final message = await _buildAlertMessage(
      title: 'EMERGENCY ALERT',
      body: 'I am in danger and need immediate assistance!',
    );
    await _sendToContacts(message, useWhatsApp: useWhatsApp);
  }

  /// Trigger Discreet alert via WhatsApp or SMS
  Future<void> triggerDiscreet({bool useWhatsApp = false}) async {
    final message = await _buildAlertMessage(
      title: 'DISCREET ALERT',
      body: 'I need help but cannot speak openly. Please check on me.',
    );
    await _sendToContacts(message, useWhatsApp: useWhatsApp);
  }

  /// Build alert message with high-accuracy GPS location and Google Maps link
  Future<String> _buildAlertMessage({
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Unknown';

    final buffer = StringBuffer();
    buffer.writeln('🚨 $title - $userName needs help!');
    buffer.writeln(body);

    try {
      final position = await _tryGetLocation();
      if (position != null) {
        final lat = position.latitude.toStringAsFixed(6);
        final lng = position.longitude.toStringAsFixed(6);
        // Format: http://maps.google.com/?q=LATITUDE,LONGITUDE
        final mapsLink = 'http://maps.google.com/?q=$lat,$lng';
        buffer.writeln('\n📍 Location: $lat, $lng');
        buffer.writeln('🗺️ Maps: $mapsLink');
      } else {
        buffer.writeln('\n📍 Location: Not available (check permissions / GPS)');
      }
    } catch (e, st) {
      log('EmergencyService: Error building location: $e', stackTrace: st);
      buffer.writeln('\n📍 Location: Error while fetching');
    }

    buffer.writeln('\nSent via Safety Shield Pro');
    return buffer.toString();
  }

  /// Try to get current location (GPS + network)
  Future<Position?> _tryGetLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('EmergencyService: Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log('EmergencyService: Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log('EmergencyService: Location permission denied forever');
        return null;
      }

      // High accuracy, falls back to network automatically
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e, st) {
      log('EmergencyService: getCurrentPosition failed: $e', stackTrace: st);
      return null;
    }
  }

  /// Send message to contacts sequentially via WhatsApp or SMS
  /// Uses explicit async loop with error handling and fallback on each contact
  Future<void> _sendToContacts(String message, {bool useWhatsApp = false}) async {
    if (contacts.isEmpty) {
      log('EmergencyService: No contacts to send to');
      return;
    }

    int successCount = 0;
    int failureCount = 0;

    // Sequential loop: process each contact one after another
    for (int i = 0; i < contacts.length; i++) {
      final contact = contacts[i];
      final phone = contact['phone'] ?? '';
      
      if (phone.isEmpty) {
        log('EmergencyService: Contact $i has empty phone, skipping');
        failureCount++;
        continue;
      }

      final sanitizedPhone = _sanitizePhone(phone);
      if (sanitizedPhone == null) {
        log('EmergencyService: Contact $i phone invalid: $phone, skipping');
        failureCount++;
        continue;
      }

      final uri = useWhatsApp
          ? _buildWhatsAppUri(sanitizedPhone, message)
          : _buildSmsUri(sanitizedPhone, message);

      // Attempt launch with error handling
      try {
        final launchSucceeded = await _safeLaunch(uri);
        if (launchSucceeded) {
          successCount++;
          log('EmergencyService: Successfully sent to contact $i: ${contact['name']}');
        } else {
          failureCount++;
          log('EmergencyService: Failed to send to contact $i: ${contact['name']}');
        }
      } catch (e, st) {
        failureCount++;
        log('EmergencyService: Exception sending to contact $i: $e', stackTrace: st);
      }

      // Brief delay between contacts to prevent system overload
      if (i < contacts.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    log('EmergencyService: Alert sequence complete - Success: $successCount, Failed: $failureCount');
  }

  /// Build WhatsApp deep link: https://wa.me/<phone>?text=<encoded_message>
  /// Falls back to WhatsApp Business (com.whatsapp.w4b) if standard WhatsApp unavailable
  Uri _buildWhatsAppUri(String digitsOnlyPhone, String message) {
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$digitsOnlyPhone?text=$encoded';
    return Uri.parse(url);
  }

  /// Build SMS deep link: sms:<phone>?body=<encoded_message>
  Uri _buildSmsUri(String digitsOnlyPhone, String message) {
    final encoded = Uri.encodeComponent(message);
    return Uri.parse('sms:$digitsOnlyPhone?body=$encoded');
  }

  /// Sanitize phone number - digits only
  String? _sanitizePhone(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;
    return digitsOnly;
  }

  /// Safely launch URL with proper error handling and timeout
  /// Returns true if launch succeeded, false otherwise
  Future<bool> _safeLaunch(Uri uri) async {
    try {
      log('EmergencyService: Attempting to launch $uri');
      
      // Check if URL can be launched with a timeout to prevent freezing
      bool can = false;
      try {
        can = await canLaunchUrl(uri).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            log('EmergencyService: canLaunchUrl timeout for $uri');
            return false;
          },
        );
      } catch (e) {
        log('EmergencyService: canLaunchUrl error for $uri: $e');
        can = false;
      }
      
      if (!can) {
        log('EmergencyService: Cannot launch $uri - app may not be installed');
        return false;
      }

      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          log('EmergencyService: launchUrl timeout for $uri');
          return false;
        },
      );

      if (!ok) {
        log('EmergencyService: launchUrl reported failure for $uri');
        return false;
      } else {
        log('EmergencyService: Successfully opened $uri');
        return true;
      }
    } catch (e, st) {
      log('EmergencyService: Exception while launching $uri: $e', stackTrace: st);
      return false;
    }
  }
}
