import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartcoaster/model/model.dart';
import 'package:smartcoaster/widgets/glass.dart';

class ScannedScreen extends StatelessWidget {
  const ScannedScreen({super.key, required this.device});
  final Device device;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0), // Add some padding inside the container
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16), // Round corners
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundImage:
                    AssetImage('assets/_logo.png'), // Correct usage
              ),
              const SizedBox(width: 16), // Spacing between avatar and text

              // Wrap this column in Expanded to avoid overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    device.isConnecting
                        ? Text(
                            'Connected',
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            'Ready to connect',
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                    if (device.isConnecting)
                      Container(
                        width: 260,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(
                              8), // Round corners for inner container
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Drink Name:",
                              style: GoogleFonts.robotoMono(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              device.drinkName,
                              style: GoogleFonts.robotoMono(
                                fontSize: 13,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12), // Spacing between text and icon

              if (device.isConnecting)
                Container(
                  height: 93,
                  width: 45, // Reduced width to avoid overflow
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Glass(
                          size: 63,
                          fillLevel: device.levelDrink / 100,
                          imageOverlay: Image.asset("assets/l.png"),
                          waterColor: getBarColor(device.levelDrink),
                          backgroundColor: Colors.grey[800]),
                      Text(
                        '${device.levelDrink}%',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(width: 8), // Add some spacing between icons

              Column(
                children: [
                  const SizedBox(height: 15), // Add some spacing
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16, // Adjust size to fit better
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.end, // Aligns everything to the right
            children: [
              const Spacer(), // Pushes the Divider to the right
              SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.65, // Adjust the width of the divider as needed
                child: Divider(
                  height: 20,
                  color: Colors.grey[875], // Change color if needed
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
