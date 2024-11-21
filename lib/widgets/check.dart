import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalibrationWidget extends StatefulWidget {
  final VoidCallback onFinish;

  const CalibrationWidget({super.key, required this.onFinish});

  @override
  _CalibrationWidgetState createState() => _CalibrationWidgetState();
}

class _CalibrationWidgetState extends State<CalibrationWidget> {
  int _currentStep = 0; // Current step index
  final int _totalSteps =
      5; // Total number of steps, including "Start Calibration"

  // List of step descriptions
  final List<String> _stepTexts = [
    'Start Calibration',
    'Step 1 Remove all objects from the coaster. Wait 5-10 seconds, then press Next',
    'Step 2 Place an empty cup on the coaster. Wait 5-10 seconds, then press Next',
    'Step 3 Fill the cup halfway. Wait 5-10 seconds, then press Next.',
    'Step 4 Fill the cup completely. Wait 5-10 seconds, then press Next',
  ];

  // Handle the button press for the next or finish step
  void _handleNextStep() {
    if (_currentStep + 1 < _totalSteps) {
      setState(() {
        _currentStep++; // Move to the next step
      });
    } else {
      widget.onFinish(); // Trigger the finish callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content vertically
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Calibration',
            style: GoogleFonts.robotoMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Step Description
          Text(
            _stepTexts[_currentStep],
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),

          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey[700],
            valueColor:
                AlwaysStoppedAnimation<Color>(Colors.blue), // Progress color
          ),
          const SizedBox(height: 24),

          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed:
                    _handleNextStep, // Call _handleNextStep on button press
                child: Text(
                  _currentStep < _totalSteps - 1 ? 'Next' : 'Finish',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CalibrationWidget(
          onFinish: () {
            print('Calibration Finished!');
          },
        ),
      ),
    ),
  ));
}
