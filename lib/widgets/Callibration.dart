import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class CalibrationWidget extends StatefulWidget {
  final VoidCallback onFinish;
  final BluetoothDevice bluetoothDevice;

  const CalibrationWidget(
      {super.key, required this.onFinish, required this.bluetoothDevice});

  @override
  _CalibrationWidgetState createState() => _CalibrationWidgetState();
}

class _CalibrationWidgetState extends State<CalibrationWidget> {
  int _currentStep = 0; // Current step index
  final int _totalSteps =
      5; // Total number of steps, including "Start Calibration"

  @override
  void initState() {
    super.initState();
    _sendCalibrationMessage(
        0); // Send step_value 0 (Start Calibration) when widget is displayed
  }

  // List of step descriptions, including "Start Calibration" as the first step
  final List<String> _stepTexts = [
    'Start Calibration', // Initial step
    'Step 1: Connect your device to the app.',
    'Step 2: Calibrate the sensor sensitivity.',
    'Step 3: Set your preferred alert settings.',
    'Step 4: Finalize and save your settings.',
  ];

  // Method to send calibration message to Bluetooth device
  void _sendCalibrationMessage(int stepValue) async {
    Map<String, dynamic> commandData = {"a": "cal", "v": stepValue};
    if (stepValue == 4) {
      commandData = {"a": "save"}; // Send save command on step 4
    }

    // Discover Bluetooth services and characteristics
    List<BluetoothService> services =
        await widget.bluetoothDevice.discoverServices();
    BluetoothCharacteristic? targetCharacteristic;

    // Find the required characteristic
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() ==
            "01924279-d023-7b9c-ba06-cb9b1dc07eda") {
          targetCharacteristic = characteristic;
          break;
        }
      }
      if (targetCharacteristic != null) {
        break;
      }
    }

    // Send the command if the characteristic is found
    if (targetCharacteristic != null) {
      String jsonData = jsonEncode(commandData); // Convert the command to JSON
      List<int> bytesToSend = utf8.encode(jsonData);
      await targetCharacteristic.write(bytesToSend, allowLongWrite: true);

      print("Sent calibration step $stepValue to the device.");
    } else {
      print("Characteristic not found!");
    }
  }

  // Handle the button press for the next or finish step
  void _handleNextStep() {
    if (_currentStep + 1 < _totalSteps) {
      _sendCalibrationMessage(
          _currentStep); // Send Bluetooth message for the current step
      setState(() {
        _currentStep++; // Move to the next step
      });
    } else {
      // Finish calibration and send the final save command
      _sendCalibrationMessage(4); // Send save command on finish
      widget.onFinish();
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
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
