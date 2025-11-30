import 'dart:io';

void main() {
  final screensDir = Directory('lib/screens');
  final files = screensDir.listSync().where((f) => f.path.endsWith('.dart'));
  
  final replacements = [
    // Padding
    ['const EdgeInsets.all(20)', 'EdgeInsets.all(MediaQuery.of(context).size.width * 0.05)'],
    ['const EdgeInsets.all(16)', 'EdgeInsets.all(MediaQuery.of(context).size.width * 0.04)'],
    ['const EdgeInsets.all(12)', 'EdgeInsets.all(MediaQuery.of(context).size.width * 0.03)'],
    ['const EdgeInsets.all(8)', 'EdgeInsets.all(MediaQuery.of(context).size.width * 0.02)'],
    
    // SizedBox
    ['const SizedBox(height: 32)', 'SizedBox(height: MediaQuery.of(context).size.height * 0.04)'],
    ['const SizedBox(height: 24)', 'SizedBox(height: MediaQuery.of(context).size.height * 0.03)'],
    ['const SizedBox(height: 20)', 'SizedBox(height: MediaQuery.of(context).size.height * 0.025)'],
    ['const SizedBox(height: 16)', 'SizedBox(height: MediaQuery.of(context).size.height * 0.02)'],
    ['const SizedBox(height: 12)', 'SizedBox(height: MediaQuery.of(context).size.height * 0.015)'],
    ['const SizedBox(height: 8)', 'SizedBox(height: MediaQuery.of(context).size.height * 0.01)'],
    ['const SizedBox(width: 20)', 'SizedBox(width: MediaQuery.of(context).size.width * 0.05)'],
    ['const SizedBox(width: 16)', 'SizedBox(width: MediaQuery.of(context).size.width * 0.04)'],
    ['const SizedBox(width: 12)', 'SizedBox(width: MediaQuery.of(context).size.width * 0.03)'],
    ['const SizedBox(width: 8)', 'SizedBox(width: MediaQuery.of(context).size.width * 0.02)'],
    
    // Font sizes
    ['fontSize: 32,', 'fontSize: MediaQuery.of(context).size.width * 0.08,'],
    ['fontSize: 28,', 'fontSize: MediaQuery.of(context).size.width * 0.07,'],
    ['fontSize: 24,', 'fontSize: MediaQuery.of(context).size.width * 0.06,'],
    ['fontSize: 20,', 'fontSize: MediaQuery.of(context).size.width * 0.05,'],
    ['fontSize: 18,', 'fontSize: MediaQuery.of(context).size.width * 0.045,'],
    ['fontSize: 16,', 'fontSize: MediaQuery.of(context).size.width * 0.04,'],
    ['fontSize: 14,', 'fontSize: MediaQuery.of(context).size.width * 0.035,'],
    ['fontSize: 12,', 'fontSize: MediaQuery.of(context).size.width * 0.03,'],
    
    // Icon sizes
    ['size: 32,', 'size: MediaQuery.of(context).size.width * 0.08,'],
    ['size: 28,', 'size: MediaQuery.of(context).size.width * 0.07,'],
    ['size: 24,', 'size: MediaQuery.of(context).size.width * 0.06,'],
    ['size: 20,', 'size: MediaQuery.of(context).size.width * 0.05,'],
    ['size: 18,', 'size: MediaQuery.of(context).size.width * 0.045,'],
    ['size: 16,', 'size: MediaQuery.of(context).size.width * 0.04,'],
    
    // Border radius
    ['BorderRadius.circular(20)', 'BorderRadius.circular(MediaQuery.of(context).size.width * 0.05)'],
    ['BorderRadius.circular(16)', 'BorderRadius.circular(MediaQuery.of(context).size.width * 0.04)'],
    ['BorderRadius.circular(12)', 'BorderRadius.circular(MediaQuery.of(context).size.width * 0.03)'],
    ['BorderRadius.circular(8)', 'BorderRadius.circular(MediaQuery.of(context).size.width * 0.02)'],
  ];
  
  for (final file in files) {
    final content = File(file.path).readAsStringSync();
    String updatedContent = content;
    
    for (final replacement in replacements) {
      updatedContent = updatedContent.replaceAll(replacement[0], replacement[1]);
    }
    
    if (content != updatedContent) {
      File(file.path).writeAsStringSync(updatedContent);
      print('Updated: ${file.path.split('/').last}');
    }
  }
  
  print('All screens updated with MediaQuery!');
}