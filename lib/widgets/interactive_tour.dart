import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final int? tabIndex;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.tabIndex,
  });
}

class InteractiveTourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final ValueChanged<int>? onStepChanged;

  const InteractiveTourOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
    this.onStepChanged,
  });

  @override
  State<InteractiveTourOverlay> createState() => _InteractiveTourOverlayState();
}

class _InteractiveTourOverlayState extends State<InteractiveTourOverlay> {
  int _currentStepIndex = 0;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTargetRect();
    });
  }

  void _calculateTargetRect() {
    if (widget.steps.isEmpty || _currentStepIndex >= widget.steps.length) return;
    
    final step = widget.steps[_currentStepIndex];
    final key = step.targetKey;
    final context = key.currentContext;
    
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      setState(() {
        _targetRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
      });
    } else {
      // Retry in next frame if context isn't ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateTargetRect();
      });
    }
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      if (widget.onStepChanged != null) {
        widget.onStepChanged!(_currentStepIndex);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateTargetRect();
      });
    } else {
      widget.onComplete();
    }
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      if (widget.onStepChanged != null) {
        widget.onStepChanged!(_currentStepIndex);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateTargetRect();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty || _currentStepIndex >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final currentStep = widget.steps[_currentStepIndex];
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return Stack(
      children: [
        // Backdrop with Cutout
        Positioned.fill(
          child: CustomPaint(
            painter: TourBackdropPainter(targetRect: _targetRect),
          ),
        ),

        // Blocking Gesture Detector to prevent interaction with background
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _nextStep,
            child: const SizedBox.shrink(),
          ),
        ),

        // Tooltip Card
        if (_targetRect != null) _buildTooltipCard(currentStep, screenSize),
      ],
    );
  }

  Widget _buildTooltipCard(TourStep step, Size screenSize) {
    final targetCenterY = _targetRect!.top + _targetRect!.height / 2;
    final showAbove = targetCenterY > screenSize.height / 2;

    // Horizontal alignment
    double cardWidth = 260.0;
    double targetCenterX = _targetRect!.left + _targetRect!.width / 2;
    double left = targetCenterX - cardWidth / 2;
    
    if (left < 16) left = 16;
    if (left + cardWidth > screenSize.width - 16) {
      left = screenSize.width - cardWidth - 16;
    }

    double? top;
    double? bottom;
    if (showAbove) {
      bottom = screenSize.height - _targetRect!.top + 12.0;
    } else {
      top = _targetRect!.bottom + 12.0;
    }

    return Positioned(
      left: left,
      top: top,
      bottom: bottom,
      width: cardWidth,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: Material(
          key: ValueKey(_currentStepIndex),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // If tooltip is below target, draw small arrow pointing up
              if (!showAbove) _buildArrow(isUp: true, targetCenterX: targetCenterX, cardLeft: left),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderGreen,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.9),
                          const Color(0xFFC0E1C6).withOpacity(0.85),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                step.title,
                                style: const TextStyle(
                                  color: AppColors.primaryTurf,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.onSkip,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: AppColors.textDarkMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.description,
                          style: const TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_currentStepIndex + 1} of ${widget.steps.length}',
                              style: const TextStyle(
                                color: AppColors.textDarkMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_currentStepIndex > 0) ...[
                                  Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTurf.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 14.5,
                                        color: AppColors.primaryTurf,
                                      ),
                                      onPressed: _prevStep,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                SizedBox(
                                  height: 26,
                                  width: 55,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryTurf,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _nextStep,
                                    child: Text(
                                      _currentStepIndex == widget.steps.length - 1 ? 'Finish' : 'Next',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // If tooltip is above target, draw small arrow pointing down
              if (showAbove) _buildArrow(isUp: false, targetCenterX: targetCenterX, cardLeft: left),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow({required bool isUp, required double targetCenterX, required double cardLeft}) {
    double arrowLeft = targetCenterX - cardLeft - 8.0;
    if (arrowLeft < 16) arrowLeft = 16;
    if (arrowLeft > 260.0 - 32) arrowLeft = 260.0 - 32;

    return Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(left: arrowLeft),
      child: CustomPaint(
        size: const Size(16, 8),
        painter: TooltipArrowPainter(isUp: isUp),
      ),
    );
  }
}

class TourBackdropPainter extends CustomPainter {
  final Rect? targetRect;

  TourBackdropPainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    
    if (targetRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final padding = 6.0;
    final holeRect = Rect.fromLTRB(
      targetRect!.left - padding,
      targetRect!.top - padding,
      targetRect!.right + padding,
      targetRect!.bottom + padding,
    );
    
    final holePath = Path()..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(12)));
    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, holePath);
    
    canvas.drawPath(combinedPath, paint);

    final highlightPaint = Paint()
      ..color = AppColors.borderGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(12)), highlightPaint);
  }

  @override
  bool shouldRepaint(covariant TourBackdropPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}

class TooltipArrowPainter extends CustomPainter {
  final bool isUp;

  TooltipArrowPainter({required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.borderGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    if (isUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
    
    final borderPath = Path();
    if (isUp) {
      borderPath.moveTo(0, size.height);
      borderPath.lineTo(size.width / 2, 0);
      borderPath.lineTo(size.width, size.height);
    } else {
      borderPath.moveTo(0, 0);
      borderPath.lineTo(size.width / 2, size.height);
      borderPath.lineTo(size.width, 0);
    }
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
