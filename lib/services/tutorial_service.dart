import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialPrefix = 'tutorial_completed_';

  static Future<bool> isTutorialCompleted(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_tutorialPrefix$tutorialId') ?? false;
  }

  static Future<void> markTutorialCompleted(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_tutorialPrefix$tutorialId', true);
  }

  static Future<void> resetTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_tutorialPrefix$tutorialId');
  }

  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_tutorialPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}