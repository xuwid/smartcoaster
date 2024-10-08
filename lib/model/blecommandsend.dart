import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  BluetoothDevice? device;
  BluetoothCharacteristic? targetCharacteristic;
  Timer? periodicTimer;

  factory BleService() {
    return _instance;
  }

  BleService._internal();

  // Initialize with the BLE device
  void initialize(BluetoothDevice bleDevice) {
    device = bleDevice;
    discoverCharacteristic();
  }

  // Discover BLE characteristics
  Future<void> discoverCharacteristic() async {
    if (device == null) return;

    List<BluetoothService> services = await device!.discoverServices();
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

    if (targetCharacteristic == null) {
      print("Characteristic not found!");
    }
  }

  // Send data to the BLE device
  Future<void> sendData() async {
    if (targetCharacteristic != null) {
      Map<String, String> commandData = {
        "a": "key",
        "key": "01924279-d023-72b2-8c96-434b3c4dcdee"
      };
      String jsonData = jsonEncode(commandData);
      List<int> bytesToSend = utf8.encode(jsonData);
      await targetCharacteristic!.write(bytesToSend, allowLongWrite: true);
    } else {
      print("No characteristic found to send data.");
    }
  }

  // Start sending data periodically (every 5 seconds)
  void startSendingDataPeriodically() {
    stopSendingData(); // Ensure there's no existing timer
    periodicTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      sendData();
    });
  }

  // Stop sending data (if necessary)
  void stopSendingData() {
    periodicTimer?.cancel();
  }
}
