import 'package:flutter/material.dart';
import 'app_colors.dart';

enum SnackBarType { success, error, info, warning }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Clear any active SnackBars first to avoid stacking
    scaffoldMessenger.hideCurrentSnackBar();

    Color backgroundColor;
    Color borderColor;
    IconData iconData;
    Color iconColor;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = AppColors.primaryTurf; // Dark Forest Green
        borderColor = const Color(0xFF4CAF50);     // Turf Accent Green
        iconData = Icons.check_circle_rounded;
        iconColor = const Color(0xFF81C784);
        break;
      case SnackBarType.error:
        backgroundColor = const Color(0xFF4A1515); // Deep Red/Burgundy
        borderColor = const Color(0xFFEF5350);     // Soft Red Accent
        iconData = Icons.error_outline_rounded;
        iconColor = const Color(0xFFE57373);
        break;
      case SnackBarType.warning:
        backgroundColor = const Color(0xFF3E2D0F); // Deep Bronze/Gold
        borderColor = const Color(0xFFFFB74D);     // Soft Orange/Gold Accent
        iconData = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFFFD54F);
        break;
      case SnackBarType.info:
      default:
        backgroundColor = AppColors.primaryTurf;   // Deep Turf Green
        borderColor = const Color(0xFF4CAF50);         // Stump Gold
        iconData = Icons.info_outline_rounded;
        iconColor = const Color(0xFF81C784);
        break;
    }

    final snackBar = SnackBar(
      elevation: 2.0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      content: Row(
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 22.0,
          ),
          const SizedBox(width: 12.0),
          Container(
            width: 1.2,
            height: 22.0,
            color: borderColor.withOpacity(0.3),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );

    scaffoldMessenger.showSnackBar(snackBar);
  }
}
