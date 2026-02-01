import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _notificationsMutedKey = 'notifications_muted';
  
  static Future<bool> areNotificationsMuted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsMutedKey) ?? false;
  }
  
  static Future<void> setNotificationsMuted(bool muted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsMutedKey, muted);
  }
}