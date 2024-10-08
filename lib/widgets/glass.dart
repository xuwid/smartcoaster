import 'package:flutter/material.dart';

class Glass extends StatefulWidget {
  final double size; // Size (height) of the glass and its elements
  final double fillLevel; // Water level (0 to 1)
  final Color waterColor; // Color of the water
  final Image imageOverlay; // Image to overlay on top
  Color? backgroundColor;

  // Constructor
  Glass({
    this.backgroundColor,
    super.key,
    required this.size,
    required this.fillLevel,
    this.waterColor = Colors.blue, // Default water color
    required this.imageOverlay, // The image to display on top
  });

  @override
  _GlassState createState() => _GlassState();
}

class _GlassState extends State<Glass> with TickerProviderStateMixin {
  // Controllers
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _wobbleController;
  late Animation<double> _wobbleAnimation;

  bool _isImageLoaded = false; // Flag to track if the image is loaded

  @override
  void initState() {
    super.initState();

    // Initialize the main water animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duration for the fill animation
    );

    // Fill up the glass from 0 to the specified fill level (tween is transition between end and start values)
    _animation = Tween<double>(begin: 0, end: widget.fillLevel).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.bounceOut,
      ),
    );

    // Initialize wobble animation
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Duration of wobble
    );

    // Define wobble animation
    _wobbleAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _wobbleController,
        curve: Curves.elasticOut, // Elastic curve for wobble effect
      ),
    );

    // Delay the water animation until the image is loaded
    _startWaterAnimationAfterImageLoad();
  }

  // Function to delay the water animation until after the image is loaded
  void _startWaterAnimationAfterImageLoad() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isImageLoaded = true;
      });

      // Animate to 10 levels above the fill level initially
      _animation = Tween<double>(begin: 0, end: widget.fillLevel + 0.1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );

      // Start the animation
      _controller.forward().then((_) {
        // After reaching the higher level, animate back to the original fill level
        _animation =
            Tween<double>(begin: widget.fillLevel + 0.1, end: widget.fillLevel)
                .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOut,
          ),
        );

        // Reset the controller and play the animation back to the fill level
        _controller.forward(from: 0);
      });
    });
  }

  @override
  void didUpdateWidget(covariant Glass oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fillLevel != widget.fillLevel) {
      _animation = Tween<double>(begin: 0, end: widget.fillLevel).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
          reverseCurve: Curves.bounceOut,
        ),
      );
      _controller.forward(from: 0); // Restart animation from empty
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 0.5, // Glass width (half the height)
      height: widget.size, // Full glass height (widget.size)
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glass color (grey)
          Container(
            width: widget.size *
                0.5, // Background width now matches the new water width
            height: widget.size, // Background height (same as glass size)
            color: widget.backgroundColor ??
                Colors.grey[900], // Glass background color
          ),
          // Water inside the glass
          if (_isImageLoaded) ...[
            Align(
              alignment: Alignment.bottomCenter, // Align water to bottom
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  // Water wobbles when the level is reached
                  if (_animation.value >= widget.fillLevel &&
                      !_wobbleController.isAnimating) {
                    _wobbleController.forward().then((_) {
                      _wobbleController.reverse(); // Settle the water
                    });
                  }
                  return ClipPath(
                    clipper:
                        WaterShape(_animation.value), // Clip the water path
                    child: Container(
                      width: widget.size *
                          0.5, // Water width is now half of the glass height
                      height: widget.size, // Water height (full glass height)
                      color: widget.waterColor,
                      transform: Matrix4.translationValues(
                          0,
                          _animation.value == widget.fillLevel
                              ? _wobbleAnimation.value
                              : 0,
                          0),
                    ),
                  );
                },
              ),
            ),
          ],
          // Image overlay on top
          Positioned.fill(
            child: SizedBox(
              width: widget.size *
                  0.5, // Image width matches water and background width
              height: widget.size, // Image height (full glass height)
              child: FittedBox(
                fit: BoxFit.cover, // Ensure image covers the whole area
                child: widget
                    .imageOverlay, // The image to overlay on top of the glass
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// String _getCurrentTime() {
//   final now = DateTime.now();
//   String hour = now.hourOfPeriod.toString().padLeft(2, '0');
//   String minute = now.minute.toString().padLeft(2, '0');
//   String period = now.hour >= 12 ? 'pm' : 'am';
//   return '$hour:$minute $period';
// }

// Water inside the glass
class WaterShape extends CustomClipper<Path> {
  final double fillPercent;

  WaterShape(this.fillPercent);

  @override
  Path getClip(Size size) {
    Path path = Path();

    // Water height based on fill percentage
    double waterHeight = size.height * (1 - fillPercent);

    // Calculate left and right positions based on the fill
    double leftX = size.width * 0.1 + (size.width * 0.05 * fillPercent);
    double rightX = size.width * 0.9 - (size.width * 0.05 * fillPercent);

    // Water top line - creating curves
    path.moveTo(leftX, waterHeight);
    path.quadraticBezierTo(
      size.width * 0.15,
      waterHeight -
          (size.height *
              0.05 *
              (1 - fillPercent)), // Control point for left curve
      leftX, waterHeight,
    );

    path.lineTo(rightX, waterHeight);

    path.quadraticBezierTo(
      size.width * 0.85,
      waterHeight -
          (size.height *
              0.05 *
              (1 - fillPercent)), // Control point for right curve
      rightX, waterHeight,
    );

    // Bottom right corner of the glass
    path.lineTo(size.width * 0.9, size.height);

    // Bottom left corner of the glass
    path.lineTo(size.width * 0.1, size.height);

    // Close the water shape
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
