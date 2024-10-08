import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class WifiConfigWidget extends StatefulWidget {
  final VoidCallback onConnect;
  final BluetoothDevice bluetoothDevice;

  const WifiConfigWidget(
      {super.key, required this.onConnect, required this.bluetoothDevice});

  @override
  _WifiConfigWidgetState createState() => _WifiConfigWidgetState();
}

class _WifiConfigWidgetState extends State<WifiConfigWidget> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isConnecting = false;

  void sendWifiInformation(BluetoothDevice device) async {
    String ssid = _ssidController.text.trim();
    String password = _passwordController.text.trim();

    if (ssid.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both SSID and Password')),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      // Prepare Wi-Fi data in JSON format
      Map<String, String> commandData = {"a": "wc", "n": ssid, "p": password};
      String jsonData = jsonEncode(commandData);
      List<int> bytesToSend = utf8.encode(jsonData);

      // Discover Bluetooth services
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? targetCharacteristic;

      // Find the required characteristic
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
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

      if (targetCharacteristic != null) {
        // Write data to the characteristic
        await targetCharacteristic.write(bytesToSend, allowLongWrite: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WiFi Information Sent')),
        );
        widget.onConnect();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to find Bluetooth characteristic')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending WiFi information: $e')),
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _connectWifi() {
    sendWifiInformation(widget.bluetoothDevice);
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WiFi Configuration',
            style: GoogleFonts.robotoMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ssidController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'SSID',
              labelStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isConnecting ? null : _connectWifi,
              child: _isConnecting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Connect',
                      style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
