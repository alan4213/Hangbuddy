import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityUtils {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: IOSAccessibility.first_unlock_this_device,
    ),
  );

  // Generate secure random string
  static String generateSecureToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Hash sensitive data
  static String hashData(String data, {String? salt}) {
    salt ??= generateSecureToken(16);
    final bytes = utf8.encode(data + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  // Verify hashed data
  static bool verifyHash(String data, String hashedData) {
    final parts = hashedData.split(':');
    if (parts.length != 2) return false;
    
    final salt = parts[0];
    final hash = parts[1];
    final newHash = hashData(data, salt: salt);
    return newHash.split(':')[1] == hash;
  }

  // Secure storage operations
  static Future<void> storeSecurely(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw SecurityException('Failed to store data securely: $e');
    }
  }

  static Future<String?> readSecurely(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw SecurityException('Failed to read secure data: $e');
    }
  }

  static Future<void> deleteSecurely(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw SecurityException('Failed to delete secure data: $e');
    }
  }

  static Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw SecurityException('Failed to clear secure data: $e');
    }
  }

  // Simple encryption for non-critical data
  static String encryptSimple(String data, String key) {
    final keyBytes = utf8.encode(key.padRight(32, '0').substring(0, 32));
    final dataBytes = utf8.encode(data);
    final encrypted = <int>[];
    
    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }

  static String decryptSimple(String encryptedData, String key) {
    try {
      final keyBytes = utf8.encode(key.padRight(32, '0').substring(0, 32));
      final encryptedBytes = base64.decode(encryptedData);
      final decrypted = <int>[];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw SecurityException('Failed to decrypt data: $e');
    }
  }

  // Validate file uploads
  static bool isValidImageFile(String fileName, List<int> fileBytes) {
    // Check file extension
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = fileName.split('.').last.toLowerCase();
    if (!validExtensions.contains(extension)) return false;

    // Check file signature (magic numbers)
    if (fileBytes.length < 4) return false;
    
    // JPEG
    if (fileBytes[0] == 0xFF && fileBytes[1] == 0xD8) return true;
    // PNG
    if (fileBytes[0] == 0x89 && fileBytes[1] == 0x50 && 
        fileBytes[2] == 0x4E && fileBytes[3] == 0x47) return true;
    // GIF
    if (fileBytes[0] == 0x47 && fileBytes[1] == 0x49 && fileBytes[2] == 0x46) return true;
    // WebP
    if (fileBytes.length >= 12 && 
        fileBytes[0] == 0x52 && fileBytes[1] == 0x49 && 
        fileBytes[2] == 0x46 && fileBytes[3] == 0x46 &&
        fileBytes[8] == 0x57 && fileBytes[9] == 0x45 && 
        fileBytes[10] == 0x42 && fileBytes[11] == 0x50) return true;

    return false;
  }

  // Check for malicious URLs
  static bool isSafeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Only allow HTTPS
      if (uri.scheme != 'https') return false;
      
      // Block suspicious domains
      final suspiciousDomains = [
        'bit.ly', 'tinyurl.com', 'goo.gl', 't.co',
        'malware.com', 'phishing.com', 'spam.com'
      ];
      
      for (final domain in suspiciousDomains) {
        if (uri.host.contains(domain)) return false;
      }
      
      // Block suspicious paths
      final suspiciousPaths = [
        'javascript:', 'data:', 'vbscript:', 'file:'
      ];
      
      for (final path in suspiciousPaths) {
        if (url.toLowerCase().contains(path)) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Generate CSRF token
  static String generateCSRFToken() {
    return generateSecureToken(32);
  }

  // Validate CSRF token
  static bool validateCSRFToken(String token, String storedToken) {
    return token.isNotEmpty && token == storedToken;
  }

  // Sanitize user input for display
  static String sanitizeForDisplay(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  // Check password strength
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 8) return PasswordStrength.weak;
    
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int score = 0;
    if (hasUpper) score++;
    if (hasLower) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;
    if (password.length >= 12) score++;
    
    if (score < 3) return PasswordStrength.weak;
    if (score < 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  // Generate secure session ID
  static String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = generateSecureToken(16);
    return hashData('$timestamp:$random').split(':')[1];
  }

  // Validate session timeout
  static bool isSessionValid(DateTime sessionStart, Duration maxDuration) {
    return DateTime.now().difference(sessionStart) < maxDuration;
  }

  // Log security events (for monitoring)
  static void logSecurityEvent(String event, Map<String, dynamic> details) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'event': event,
      'details': details,
    };
    
    // In production, send to security monitoring service
    print('SECURITY_LOG: ${jsonEncode(logEntry)}');
  }

  // Device fingerprinting (basic)
  static Future<String> getDeviceFingerprint() async {
    // This would typically include device info, screen size, etc.
    // For now, generate a simple identifier
    final stored = await readSecurely('device_fingerprint');
    if (stored != null) return stored;
    
    final fingerprint = generateSecureToken(32);
    await storeSecurely('device_fingerprint', fingerprint);
    return fingerprint;
  }
}

enum PasswordStrength { weak, medium, strong }

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}