import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ShimmerCard extends StatefulWidget {
  final double height;
  final double width;

  const ShimmerCard({
    super.key,
    required this.height,
    required this.width,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.75).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(widget.height == widget.width ? widget.height / 2 : 6),
              border: Border.all(
                color: Colors.black.withOpacity(0.02),
                width: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class LiveMatchSkeleton extends StatelessWidget {
  final bool showScoringSection;

  const LiveMatchSkeleton({
    super.key,
    required this.showScoringSection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: showScoringSection ? 190.0 : 140.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderWood,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFBF7),
            Color(0xFFFAF2E6),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Placeholder Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerCard(height: 11, width: 120),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Team A Row Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    ShimmerCard(height: 28, width: 28), // Circular avatar placeholder
                    SizedBox(width: 10),
                    ShimmerCard(height: 14, width: 110), // Team name placeholder
                  ],
                ),
                const ShimmerCard(height: 14, width: 60), // Score placeholder
              ],
            ),
            const SizedBox(height: 10),

            // Team B Row Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    ShimmerCard(height: 28, width: 28), // Circular avatar placeholder
                    SizedBox(width: 10),
                    ShimmerCard(height: 14, width: 90), // Team name placeholder
                  ],
                ),
                const ShimmerCard(height: 14, width: 45), // Score placeholder
              ],
            ),

            const Divider(color: AppColors.borderGreen, height: 24),

            // Bottom Status Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerCard(height: 11, width: 180), // Status placeholder
                if (showScoringSection)
                  const ShimmerCard(height: 24, width: 75), // Buttons/Scoring placeholder
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UpcomingMatchSkeleton extends StatelessWidget {
  final bool showScoringButton;

  const UpcomingMatchSkeleton({
    super.key,
    required this.showScoringButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140.0,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderWood.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFBF7),
            Color(0xFFFAF2E6),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerCard(height: 11, width: 90),
                ShimmerCard(height: 11, width: 120),
              ],
            ),
            const SizedBox(height: 12),

            // Teams Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          ShimmerCard(height: 24, width: 24),
                          SizedBox(width: 8),
                          ShimmerCard(height: 12, width: 100),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          ShimmerCard(height: 24, width: 24),
                          SizedBox(width: 8),
                          ShimmerCard(height: 12, width: 80),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showScoringButton) ...[
                  const SizedBox(width: 16),
                  const ShimmerCard(height: 32, width: 68),
                ],
              ],
            ),
            const Divider(color: AppColors.dividerGreen, height: 16),
            const ShimmerCard(height: 11, width: 140),
          ],
        ),
      ),
    );
  }
}

class RecentMatchSkeleton extends StatelessWidget {
  const RecentMatchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140.0,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderWood.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFBF7),
            Color(0xFFFAF2E6),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerCard(height: 11, width: 90),
                ShimmerCard(height: 11, width: 80),
              ],
            ),
            const SizedBox(height: 10),

            // Team A
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    ShimmerCard(height: 24, width: 24),
                    SizedBox(width: 8),
                    ShimmerCard(height: 12, width: 110),
                  ],
                ),
                const ShimmerCard(height: 12, width: 45),
              ],
            ),
            const SizedBox(height: 10),

            // Team B
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    ShimmerCard(height: 24, width: 24),
                    SizedBox(width: 8),
                    ShimmerCard(height: 12, width: 90),
                  ],
                ),
                const ShimmerCard(height: 12, width: 45),
              ],
            ),
            const Divider(color: AppColors.dividerGreen, height: 16),

            // Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerCard(height: 11, width: 150),
                ShimmerCard(height: 11, width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
