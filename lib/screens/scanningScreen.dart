import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartcoaster/model/model.dart';
import 'package:smartcoaster/provider/provider.dart';
import 'package:smartcoaster/screens/bluetooth_pop_menu.dart';
import 'package:smartcoaster/screens/homescreen.dart';
import 'package:smartcoaster/widgets/Callibration.dart';
import 'package:smartcoaster/widgets/WifiConfigure.dart';
import 'package:smartcoaster/widgets/scannedDevice.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'package:smartcoaster/model/blecommandsend.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  _ScanningScreenState createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen>
    with SingleTickerProviderStateMixin {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  List<ScanResult> bluetoothDevices = [];
  List<BluetoothDevice> devs = [];
  final bool _devicesLoaded = false;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;
  late AnimationController _controller;
  late Animation<double> _animation;
  List<Device> BluetoothDevices = [];
  List<ScanResult> PrevbluetoothDevices = [];
  final DeviceProvider _deviceProvider = DeviceProvider();
  // Boolean to show loading state
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

  @override
  void initState() {
    super.initState();

    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
    scanBluetooth(context);

    //Run this after every 3 sec

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Define the animation
    _animation = Tween<double>(begin: 0.0, end: 40.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will now safely load devices after the build context is fully available.
    // Provider.of<DeviceProvider>(context).loadDevicesFromLocal();
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

//   Future<void> subscribeToNotifications(BluetoothDevice device) async {
//     try {
//       List<BluetoothService> services = await device.discoverServices();
//       BluetoothCharacteristic? notifyCharacteristic;

//       // Find the characteristic that sends notifications
//       for (BluetoothService service in services) {
//         for (BluetoothCharacteristic characteristic
//             in service.characteristics) {
//           if (characteristic.uuid.toString() ==
//               "01924279-d023-7b9c-ba06-cb9b1dc07eda") {
//             notifyCharacteristic = characteristic;
//             break;
//           }
//         }
//         if (notifyCharacteristic != null) break;
//       }

//       if (notifyCharacteristic != null) {
//         await notifyCharacteristic.setNotifyValue(true);

//         final subscription =
//             notifyCharacteristic.onValueReceived.listen((value) {
//           // Decode the received bytes
//           String receivedData = utf8.decode(value);
//           //if (receivedData.contains("a")) {

//           print("Received data from ${device.name}: $receivedData");

//           // onValueReceived is updated:
//           //   - anytime read() is called
//           //   - anytime a notification arrives (if subscribed)
//         });

// // cleanup: cancel subscription when disconnected
//         device.cancelWhenDisconnected(subscription);

// // subscribe
// // Note: If a characteristic supports both **notifications** and **indications**,
// // it will default to **notifications**. This matches how CoreBluetooth works on iOS.
//         await notifyCharacteristic.setNotifyValue(true);

//         // notifyCharacteristic.value.listen((value) {
//         //   String receivedData = utf8.decode(value); // Decode the received bytes
//         //   Map<String, dynamic> jsonData = jsonDecode(receivedData);

//         //   // Store the notification with the device information
//         //   print("Received data from ${device.name}: $jsonData");
//         //   //if it contains uuid then it is the response of the command sent
//         //   if (jsonData.containsKey("v")) {
//         //     print("Response of the command sent");
//         //     if (jsonData["a"] == "mac") {
//         //       print("Command executed successfully");
//         //       print(jsonData["v"]);
//         //       Provider.of<DeviceProvider>(context, listen: false)
//         //           .setCurrentDeviceId(jsonData["v"]);
//         //     }
//         //   }
//         // });
//       } else {
//         print("Notify characteristic not found!");
//       }
//     } catch (e) {
//       print("Error subscribing to notifications: $e");
//     }
//   }

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
        deviceName: "mals",
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
  } // Function to show Calibration Dialog

  // Future<void> afterConnectionSendData(BluetoothDevice device) async {
  //   // Define the data to be sent in a map
  //   print("Sending data to the device");
  //   Map<String, String> commandData = {
  //     "a": "key",
  //     "key": "01924279-d023-72b2-8c96-434b3c4dcdee"
  //   };
  //   String jsonData =
  //       commandData.toString(); // Or use jsonEncode(commandData) if using JSON
  //   List<int> bytesToSend = utf8.encode(jsonData);
  //   List<BluetoothService> services = await device.discoverServices();
  //   BluetoothCharacteristic? targetCharacteristic;

  //   // Loop through services to find the required characteristic
  //   for (BluetoothService service in services) {
  //     for (BluetoothCharacteristic characteristic in service.characteristics) {
  //       if (characteristic.uuid.toString() ==
  //           "01924279-d023-7b9c-ba06-cb9b1dc07eda") {
  //         targetCharacteristic = characteristic;
  //         break;
  //       }
  //     }
  //     if (targetCharacteristic != null) {
  //       break;
  //     }
  //   }
  //   // p
  //   // Write data to the found characteristic if available
  //   if (targetCharacteristic != null) {
  //     // Convert the command data to the appropriate format, such as JSON or bytes

  //     print("TargetCharacteristics is not null");

  //     // Write the data to the characteristic with long write enabled
  //     await targetCharacteristic.write(bytesToSend, allowLongWrite: true);
  //   } else {
  //     print("Characteristic not found!");
  //   }
  // }

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

//Provider.of<DeviceProvider>(context, listen: false)
              //                 .addDevice(device); // Implement this method
              Provider.of<DeviceProvider>(context, listen: false)
                  .setcurrentDeviceConfiguration(true);
              Provider.of<DeviceProvider>(context, listen: false)
                  .setcurrentDeviceConnecting(true);
              await Provider.of<DeviceProvider>(context, listen: false)
                  .updateTime(device.id, device.TSCmin * 60 + device.TSCsec);

              //plement this method
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
        );
      },
    );
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

  // void connectToDevice(BluetoothDevice dev) async {
  //   await dev.connect();
  //   await updateMTU(dev);
  //   await afterConnectionSendData(dev);
  // }

  //   Future<void> updateMTU(BluetoothDevice device) async {
  //     // Request MTU
  //     int mtu = await device.requestMtu(512);
  //     print("MTU: $mtu");
  //   }

  @override
  Widget build(BuildContext context) {
    StreamSubscription<BluetoothAdapterState>? adapterStateSubscription;
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Devices',
            style: GoogleFonts.robotoMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
                onPressed: () {
                  // Another screen should be displayed
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BluetoothScreen()));
                },
                icon: const Icon(Icons.add)),
          ],
          forceMaterialTransparency: true,
        ),
        body: Container(
            color: Colors.black,
            child: RefreshIndicator(
                onRefresh: _scanDevices, // Trigger device scan on swipe down
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  // "Scanned Devices" title text
                  Text(
                    'Added Devices',
                    style: GoogleFonts.robotoMono(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),

                  const SizedBox(
                      height: 10), // Reduced spacing between title and list

                  // Check if the list is empty or loading
                  isLoading ||
                          Provider.of<DeviceProvider>(context).devices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0,
                                        _animation.value), // Move up and down
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 225),
                                          Text(
                                            isLoading
                                                ? 'Loading...'
                                                : 'No devices', // Loading state
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            isLoading
                                                ? ''
                                                : '(Swipe down to scan)',
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      : Consumer<DeviceProvider>(
                          builder: (context, deviceProvider, child) {
                            List<Device> devices = deviceProvider.devices;
                            //devices contain only those devices whose id is unique
                            //check if the id of device is unique

                            // Only add devices that are not already in the provider's list

                            //update the previous bluetooth devices
                            //     .clear(); // Clear scanned devices after processing

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: devices.length,
                              itemBuilder: (context, index) {
                                Device device = devices[index];

                                return GestureDetector(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ScannedScreen(device: device),
                                  ),
                                  onTap: () {
                                    deviceProvider.setCurrentDevice(device);
                                    if (!device.isConfigured) {
                                      // show dialog that Device is not connected
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title:
                                                  Text("Device not connected"),
                                              content: Text(
                                                  "Please connect the device"),
                                              actions: [
                                                TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text("OK"))
                                              ],
                                            );
                                          });

                                      //    _showCalibrationDialog(device);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => HomeScreen()),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                ]))));
  }
}
