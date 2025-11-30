import 'dart:io';

class ScreenUpdater {
  static final Map<String, List<Map<String, String>>> _replacements = {
    // Common patterns to replace with MediaQuery
    'padding': [
      {'from': 'const EdgeInsets.all(20)', 'to': 'EdgeInsets.all(MediaQuery.of(context).size.width * 0.05)'},
      {'from': 'const EdgeInsets.all(16)', 'to': 'EdgeInsets.all(MediaQuery.of(context).size.width * 0.04)'},
      {'from': 'const EdgeInsets.all(12)', 'to': 'EdgeInsets.all(MediaQuery.of(context).size.width * 0.03)'},
      {'from': 'const EdgeInsets.all(8)', 'to': 'EdgeInsets.all(MediaQuery.of(context).size.width * 0.02)'},
      {'from': 'const EdgeInsets.symmetric(horizontal: 20)', 'to': 'EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05)'},
      {'from': 'const EdgeInsets.symmetric(horizontal: 16)', 'to': 'EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04)'},
      {'from': 'const EdgeInsets.symmetric(vertical: 20)', 'to': 'EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.025)'},
      {'from': 'const EdgeInsets.symmetric(vertical: 16)', 'to': 'EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02)'},
    ],
    'sizedbox': [
      {'from': 'const SizedBox(height: 32)', 'to': 'SizedBox(height: MediaQuery.of(context).size.height * 0.04)'},
      {'from': 'const SizedBox(height: 24)', 'to': 'SizedBox(height: MediaQuery.of(context).size.height * 0.03)'},
      {'from': 'const SizedBox(height: 20)', 'to': 'SizedBox(height: MediaQuery.of(context).size.height * 0.025)'},
      {'from': 'const SizedBox(height: 16)', 'to': 'SizedBox(height: MediaQuery.of(context).size.height * 0.02)'},
      {'from': 'const SizedBox(height: 12)', 'to': 'SizedBox(height: MediaQuery.of(context).size.height * 0.015)'},
      {'from': 'const SizedBox(height: 8)', 'to': 'SizedBox(height: MediaQuery.of(context).size.height * 0.01)'},
      {'from': 'const SizedBox(width: 20)', 'to': 'SizedBox(width: MediaQuery.of(context).size.width * 0.05)'},
      {'from': 'const SizedBox(width: 16)', 'to': 'SizedBox(width: MediaQuery.of(context).size.width * 0.04)'},
      {'from': 'const SizedBox(width: 12)', 'to': 'SizedBox(width: MediaQuery.of(context).size.width * 0.03)'},
      {'from': 'const SizedBox(width: 8)', 'to': 'SizedBox(width: MediaQuery.of(context).size.width * 0.02)'},
    ],
    'fontsize': [
      {'from': 'fontSize: 32', 'to': 'fontSize: MediaQuery.of(context).size.width * 0.08'},
      {'from': 'fontSize: 28', 'to': 'fontSize: MediaQuery.of(context).size.width * 0.07'},
      {'from': 'fontSize: 24', 'to': 'fontSize: MediaQuery.of(context).size.width * 0.06'},
      {'from': 'fontSize: 20', 'to': 'fontSize: MediaQuery.of(context).size.width * 0.05'},
      {'from': 'fontSize: 18', 'to': 'fontSize: MediaQuery.of(context).size.width * 0.045'},
      {'from': 'fontSize: 16', 'to': 'fontSize: MediaQuery.of(context).size.width * 0.04'},
      {'from': 'fontSize: 14', 'to': 'fontSize: MediaQuery.of(context).size.width * 0.035'},
      {'from': 'fontSize: 12', 'to': 'fontSize: MediaQuery.of(context).size.width * 0.03'},
    ],
    'borderradius': [
      {'from': 'BorderRadius.circular(20)', 'to': 'BorderRadius.circular(MediaQuery.of(context).size.width * 0.05)'},
      {'from': 'BorderRadius.circular(16)', 'to': 'BorderRadius.circular(MediaQuery.of(context).size.width * 0.04)'},
      {'from': 'BorderRadius.circular(12)', 'to': 'BorderRadius.circular(MediaQuery.of(context).size.width * 0.03)'},
      {'from': 'BorderRadius.circular(8)', 'to': 'BorderRadius.circular(MediaQuery.of(context).size.width * 0.02)'},
    ],
    'iconsize': [
      {'from': 'size: 32', 'to': 'size: MediaQuery.of(context).size.width * 0.08'},
      {'from': 'size: 28', 'to': 'size: MediaQuery.of(context).size.width * 0.07'},
      {'from': 'size: 24', 'to': 'size: MediaQuery.of(context).size.width * 0.06'},
      {'from': 'size: 20', 'to': 'size: MediaQuery.of(context).size.width * 0.05'},
      {'from': 'size: 18', 'to': 'size: MediaQuery.of(context).size.width * 0.045'},
      {'from': 'size: 16', 'to': 'size: MediaQuery.of(context).size.width * 0.04'},
    ],
  };

  static void updateAllScreens(String screensPath) {
    final directory = Directory(screensPath);
    final files = directory.listSync().where((file) => file.path.endsWith('.dart')).toList();
    
    for (final file in files) {
      updateScreen(file.path);
    }
  }

  static void updateScreen(String filePath) {
    final file = File(filePath);
    String content = file.readAsStringSync();
    
    // Apply all replacements
    _replacements.forEach((category, replacements) {
      for (final replacement in replacements) {
        content = content.replaceAll(replacement['from']!, replacement['to']!);
      }
    });
    
    file.writeAsStringSync(content);
    print('Updated: ${filePath.split('\\').last}');
  }
}