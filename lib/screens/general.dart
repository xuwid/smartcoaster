import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartcoaster/provider/provider.dart';
import 'package:smartcoaster/widgets/glass.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class GeneralScreen extends StatefulWidget {
  const GeneralScreen({super.key});

  @override
  _GeneralScreenState createState() => _GeneralScreenState();
}

String getTimeSinceLastDrink(DateTime lastDrink) {
  final currentTime = DateTime.now();
  final difference = currentTime.difference(lastDrink);

  if (difference.inMinutes < 1) {
    return '${difference.inSeconds} seconds ago';
  } else {
    return '${difference.inMinutes} minutes ago';
  }
}

class _GeneralScreenState extends State<GeneralScreen> {
  Color getBarColor(int level) {
    if (level >= 75) {
      return Colors.green;
    } else if (level >= 50) {
      return Colors.blue;
    } else if (level >= 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  DateTime _parse12HourTime(String timeString) {
    final format =
        DateFormat.jm(); // 'jm' handles the 12-hour format with am/pm
    try {
      // Clean the string: remove non-breaking spaces or other invisible characters
      timeString = timeString
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(); // Replace multiple spaces with a single space and trim

      print(
          "Parsing time string: '$timeString'"); // Debugging: print cleaned time string
      return format.parse(timeString); // Parse the cleaned string
    } catch (e) {
      print("Error parsing time: $e"); // Debugging: catch and print error
      return DateTime.now(); // Return current time on error to avoid crashes
    }
  }

  // Function to calculate time difference and return formatted string

  @override
  Widget build(BuildContext context) {
    String deviceName =
        Provider.of<DeviceProvider>(context).currentDevice!.deviceName;
    int levelDrink =
        Provider.of<DeviceProvider>(context).currentDevice!.levelDrink;
    DateTime lastDrinkServed =
        Provider.of<DeviceProvider>(context).currentDevice!.lastDrinkServed;

    double batteryPercentage =
        Provider.of<DeviceProvider>(context).currentDevice!.batteryPercentage;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'General',
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        forceMaterialTransparency: true,
        backgroundColor: Colors.grey[875],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16),
          color: Colors.black,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "Device -",
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    deviceName,
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.grey[700], height: 40),
              const SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    "Device Battery",
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${batteryPercentage.round()}%",
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                minHeight: 12,
                value: batteryPercentage / 100,
                backgroundColor: Colors.grey[700],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey[700], height: 40),
              const SizedBox(height: 15),

              // Beer bottle widget
              Glass(
                  size: 280,
                  fillLevel: levelDrink / 100,
                  imageOverlay: Image.asset("assets/GLASS3.png"),
                  waterColor: getBarColor(levelDrink),
                  backgroundColor: Colors.grey[850]),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Level - $levelDrink%",
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Divider(color: Colors.grey[700], height: 40),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "Last drink served",
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    getTimeSinceLastDrink(lastDrinkServed),
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
