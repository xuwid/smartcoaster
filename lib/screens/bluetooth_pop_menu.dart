import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartcoaster/model/model.dart';
import 'package:smartcoaster/provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smartcoaster/screens/homescreen.dart';
import 'package:smartcoaster/widgets/scannedDevice.dart';
import 'package:smartcoaster/widgets/Callibration.dart';
import 'package:smartcoaster/widgets/WifiConfigure.dart';
import 'dart:convert';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({Key? key}) : super(key: key);

  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<Device> BluetoothDevices = [];
  List<ScanResult> bluetoothDevices = [];
  List<BluetoothDevice> devs = [];
  bool isLoading = false;
  void scanBluetooth(BuildContext context) async {
    bluetoothDevices.clear();
    // Listen to the Bluetooth adapter state
    var adapterState = await FlutterBluePlus.adapterState.first;

    // Check if Bluetooth is on
    if (adapterState == BluetoothAdapterState.on) {
      // Start scanning for devices
      await FlutterBluePlus.startScan(
          withServices: [Guid("01924279-d022-73c7-a4ba-a6eb297b4681")],
          timeout: const Duration(seconds: 15));

      // Listen to scan results
      var subscription = FlutterBluePlus.scanResults.listen((results) {
        // Loop through the scan results
        for (ScanResult r in results) {
          if (r.advertisementData.advName.isNotEmpty) {
            // Check if the device is already in the list
            bool exists = bluetoothDevices
                .any((device) => device.device.remoteId == r.device.remoteId);

            // If it doesn't exist, add it tothe list
            if (!exists) {
              bluetoothDevices.add(r);
              print(
                  '${r.device.remoteId}: "${r.advertisementData.advName}" found!');
            }
          }
        }
      }, onError: (e) => print(e));

      // Wait until scanning stops
      await FlutterBluePlus.isScanning
          .where((scanning) => scanning == false)
          .first;

      // Stop listening to scan results after scan completes
      subscription.cancel();
    } else {
      // Bluetooth is off, display a message to the user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bluetooth is Off'),
            content: const Text('Please enable Bluetooth to scan for devices.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _scanDevices() async {
    setState(() {
      isLoading = true; // Start loading
    });

    scanBluetooth(context);
    await Future.delayed(const Duration(seconds: 4));

    // After loading, update the list of scanned devices
    BluetoothDevices.clear();
    for (var device in bluetoothDevices) {
      BluetoothDevices.add(Device(
        deviceName: device.advertisementData.advName,
        isConnecting: false,
        isConfigured: false,
        bluetoothDevice: device.device,
      ));
    }

    //display connected  bluetooth devices
    devs = FlutterBluePlus.connectedDevices;
    print("connected Devices");
    for (var d in devs) {
      print(d.remoteId);
    }
    //

    setState(() {
      isLoading = false; // Stop loading
    });
  }

  void connectToDevice(BluetoothDevice dev) async {
    try {
      await dev.connect();
      await updateMTU(dev);
      await afterConnectionSendData(dev);
    } catch (e) {
      print("Error connecting to device: $e");
    }
  }

  Future<void> updateMTU(BluetoothDevice device) async {
    try {
      int mtu = await device.requestMtu(512);
      print("MTU: $mtu");
    } catch (e) {
      print("Error requesting MTU: $e");
    }
  }

  Future<void> afterConnectionSendData(BluetoothDevice device) async {
    try {
      // Discover services once and cache them
      print("Discovering services...");
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? targetCharacteristic;

      // Find the characteristic once
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

      // Check if the target characteristic was found
      if (targetCharacteristic == null) {
        print("Characteristic not found!");
        return;
      } else {
        print("TargetCharacteristic is found");
      }

      // Enable notifications on the characteristic
      await targetCharacteristic.setNotifyValue(true);

      // Set up the subscription to receive data
      final subscription = targetCharacteristic.value.listen((value) {
        String receivedData = utf8.decode(value);

        // Attempt to parse the received data as JSON
        try {
          Map<String, dynamic> jsonResponse = jsonDecode(receivedData);

          // Check if the key "a" exists and its value is "mac"
          if (jsonResponse.containsKey("a") && jsonResponse["a"] == "mac") {
            // Perform the action: change the value of the current device ID
            Provider.of<DeviceProvider>(context, listen: false)
                .setCurrentDeviceId(jsonResponse["v"]);

            print(Provider.of<DeviceProvider>(context, listen: false)
                .currentDevice!
                .deviceName);
            //Display current device info
          }
        } catch (e) {
          print("Error parsing JSON: $e");
        }

        // Print the received data
        print("Received data from ${device.name}: $receivedData");
      });

      // Function to send data to the device
      Future<void> sendData(Map<String, String> commandData) async {
        String jsonData = jsonEncode(commandData);
        List<int> bytesToSend = utf8.encode(jsonData);
        await targetCharacteristic!.write(bytesToSend, withoutResponse: false);
      }

      // Send first command
      print("Sending initial command...");
      await sendData(
          {"a": "key", "key": "01924279-d023-72b2-8c96-434b3c4dcdee"});

      // Wait for a second
      await Future.delayed(const Duration(seconds: 1));

      // Send second command
      print("Sending second command...");
      await sendData({"a": "gm"});

      // Clean up: Cancel subscription when disconnected
      device.cancelWhenDisconnected(subscription);
    } catch (e) {
      print("Error during Bluetooth communication: $e");
    }
  }

  void _showCalibrationDialog(Device device) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissal by tapping outside the dialog
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: CalibrationWidget(
            bluetoothDevice: device.bluetoothDevice!,
            onFinish: () {
              print("finished calibration");
              Navigator.of(context).pop(); // Close Calibration Dialog
              _showWifiConfigDialog(device);
            },
          ),
        );
      },
    );
  }

  // Function to show WiFi Configuration Dialog
  void _showWifiConfigDialog(Device device) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissal by tapping outside the dialog
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: WifiConfigWidget(
            bluetoothDevice: device.bluetoothDevice!,
            onConnect: () async {
              // After WiFi configuration, navigate to HomeScreen
              Navigator.of(context).pop(); // Close WiFi Config Dialog
              // Optionally, update the device configuration status
              var deviceProvider =
                  Provider.of<DeviceProvider>(context, listen: false);

// Check if the device is already in the list using `any()`
              bool deviceExists =
                  deviceProvider.devices.any((d) => d.id == device.id);

              if (!deviceExists) {
                // Only add the device if it's not already in the list
                deviceProvider.addDevice(device);
              }
              deviceProvider.setcurrentDeviceConfiguration(true);
              deviceProvider.setcurrentDeviceConnecting(true);

              //  await Provider.of<DeviceProvider>(context, listen: false)
              //     .updateTime(device.id, device.TSCmin * 60 + device.TSCsec);

              //plement this method
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Device> devices = Provider.of<DeviceProvider>(context).devices;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scanning',
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _scanDevices();
            },
          ),
        ],
        forceMaterialTransparency: true,
        backgroundColor: Colors.grey[875],
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: BluetoothDevices.length,
          itemBuilder: (context, index) {
            final device = BluetoothDevices[index];
            return GestureDetector(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ScannedScreen(device: device),
              ),
              onTap: () {
                Provider.of<DeviceProvider>(context, listen: false)
                    .setCurrentDevice(device);

                connectToDevice(device.bluetoothDevice!);
                //  Navigator.of(context).pushNamed('/device');
                _showMiddleDialog(device);
              },
            );
          },
        ),
      ),
    );
  }

  void _showMiddleDialog(Device device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: Text(
            'Select Setup Option',
            style: GoogleFonts.robotoMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Description
              Text(
                'Choose one of the following setup options:',
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),

              // Progress Indicator (Optional, for visual effect)
              LinearProgressIndicator(
                value: 0.5, // Update this based on any progress logic
                backgroundColor: Colors.grey[700],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  _showCalibrationDialog(
                      device); // Navigate to Calibration setup screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Setup Calibration',
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ), // Spacing between buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  _showWifiConfigDialog(
                      device); // Navigate to Wifi setup screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Setup Wifi',
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
