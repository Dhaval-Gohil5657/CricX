import 'package:flutter/material.dart';
import 'dart:convert';
import 'app_colors.dart';

enum SnackBarType { success, error, info, warning }

class CustomSnackBar {
  static String _sanitizeMessage(String rawMessage) {
    String msg = rawMessage.trim();

    // 1. Strip common prefixes
    if (msg.startsWith('Exception:')) {
      msg = msg.substring('Exception:'.length).trim();
    }
    if (msg.startsWith('Exception')) {
      msg = msg.substring('Exception'.length).trim();
    }

    // 2. Extract embedded JSON messages
    final jsonStartIndex = msg.indexOf('{');
    final jsonEndIndex = msg.lastIndexOf('}');
    if (jsonStartIndex != -1 && jsonEndIndex != -1 && jsonEndIndex > jsonStartIndex) {
      try {
        final jsonStr = msg.substring(jsonStartIndex, jsonEndIndex + 1);
        final parsed = jsonDecode(jsonStr);
        if (parsed is Map) {
          final extractedMessage = parsed['message'] ?? parsed['error'] ?? parsed['msg'];
          if (extractedMessage != null) {
            msg = extractedMessage.toString();
          }
        }
      } catch (_) {}
    }

    // 3. Simplify HTML error pages
    final lowerMsg = msg.toLowerCase();
    if (lowerMsg.contains('<!doctype html>') || lowerMsg.contains('<html>')) {
      if (lowerMsg.contains('bad gateway')) {
        return 'Server is starting up (Bad Gateway). Please try again in a few seconds.';
      }
      if (lowerMsg.contains('service unavailable')) {
        return 'Server is temporarily unavailable. Please try again later.';
      }
      return 'Internal server error. Please try again.';
    }

    // 4. Simplify database validation messages
    if (msg.contains('validation failed:')) {
      final parts = msg.split('validation failed:');
      if (parts.length >= 2) {
        msg = parts[1].trim();
      }
    }

    // 5. Truncate very long messages
    if (msg.length > 130) {
      msg = '${msg.substring(0, 127)}...';
    }

    return msg;
  }

  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Clear any active SnackBars first to avoid stacking
    scaffoldMessenger.hideCurrentSnackBar();

    final sanitizedMessage = _sanitizeMessage(message);

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
              sanitizedMessage,
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
