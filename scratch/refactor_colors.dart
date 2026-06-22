import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  if (!dir.existsSync()) {
    print('Directory lib/screens not found.');
    return;
  }
  
  final files = dir.listSync(recursive: true);
  for (var entity in files) {
    if (entity is File && entity.path.endsWith('.dart')) {
      refactorFile(entity);
    }
  }
  print('Refactoring screens complete!');
}

void refactorFile(File file) {
  var content = file.readAsStringSync();
  
  // Replace Colors.white opacities with AppColors theme variables
  content = content.replaceAll('Colors.white70', 'AppColors.textDarkSecondary');
  content = content.replaceAll('Colors.white60', 'AppColors.textDarkSecondary');
  content = content.replaceAll('Colors.white54', 'AppColors.textDarkSecondary');
  content = content.replaceAll('Colors.white38', 'AppColors.textDarkMuted');
  content = content.replaceAll('Colors.white30', 'AppColors.textDarkMuted');
  content = content.replaceAll('Colors.white24', 'AppColors.textDarkDisabled');
  content = content.replaceAll('Colors.white12', 'AppColors.dividerGreen');
  content = content.replaceAll('Colors.white10', 'AppColors.dividerGreen');
  
  // Replace direct white colors inside TextStyles and general icon colors to adapt to light background
  content = content.replaceAll('color: Colors.white,', 'color: AppColors.textDark,');
  content = content.replaceAll('color: Colors.white)', 'color: AppColors.textDark)');
  
  // Clean up any remaining white colors in TextStyles
  content = content.replaceAll('color: const Color(0xFFB0BEC5)', 'color: AppColors.textDarkSecondary');
  
  // For ElevatedButton foregrounds or special cards where white text should remain white,
  // we can ensure they use AppColors.leatherWhite instead of Colors.white, but standard buttons will use the theme.
  
  file.writeAsStringSync(content);
}
