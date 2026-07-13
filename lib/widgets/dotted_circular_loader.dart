import 'dart:math' as math;
import 'package:flutter/material.dart';

class DottedCircularLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final int dotCount;

  final bool center;

  const DottedCircularLoader({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 1000),
    this.dotCount = 8,
    this.center = true,
  });

  @override
  State<DottedCircularLoader> createState() => _DottedCircularLoaderState();
}

class _DottedCircularLoaderState extends State<DottedCircularLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loader = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: DottedCircularPainter(
              animationValue: _controller.value,
              color: widget.color,
              dotCount: widget.dotCount,
            ),
          );
        },
      ),
    );

    if (widget.center) {
      return Center(child: loader);
    }
    return loader;
  }
}

class DottedCircularPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final int dotCount;

  DottedCircularPainter({
    required this.animationValue,
    required this.color,
    required this.dotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double outerRadius = size.width / 2;

    // Dot radius will be proportional to the outer size
    final double maxDotRadius = size.width * 0.12;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      // Calculate angle for this dot
      final double angle = (2 * math.pi * i) / dotCount;

      // Position of the dot
      final double x = centerX + math.cos(angle) * (outerRadius - maxDotRadius);
      final double y = centerY + math.sin(angle) * (outerRadius - maxDotRadius);

      // Phase is offset based on the dot index
      final double phase = (animationValue - (i / dotCount)) % 1.0;

      // Make the dot size and opacity pulse/fade trailingly
      final double scale = 0.3 + 0.7 * (1.0 - phase);
      final double opacity = math.pow(1.0 - phase, 1.5).toDouble();

      paint.color = color.withOpacity(opacity.clamp(0.0, 1.0));
      final double dotRadius = maxDotRadius * scale;

      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DottedCircularPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.dotCount != dotCount;
  }
}
