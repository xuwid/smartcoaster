import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DrinkLevel {
  final String time;
  final int level;

  DrinkLevel(this.time, this.level);

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'level': level,
    };
  }

  factory DrinkLevel.fromMap(Map<String, dynamic> map) {
    return DrinkLevel(
      map['time'],
      map['level'],
    );
  }
}

class Device {
  String? id;
  String deviceName;

  double batteryPercentage;
  int levelDrink;
  bool isConfigured;
  DateTime lastDrinkServed;
  String drinkName;
  String DrinkType;
  int DrinkSize;
  int TSCmin;
  int TSCsec;
  bool chime;
  bool vibrate;
  bool isConnecting;
  List<DrinkLevel> data;
  bool updateDeviceNameSet;
  bool updateDeviceConfigurationSet;
  bool updateAlertConfigurationSet;
  BluetoothDevice? bluetoothDevice;
  Device({
    this.bluetoothDevice,
    this.id,
    this.deviceName = 'Smart Coaster 1',
    this.batteryPercentage = 0.4,
    this.levelDrink = 80,
    DateTime? lastDrinkServed,
    this.drinkName = 'Gyn & Tonic',
    this.DrinkType = 'Glass',
    this.DrinkSize = 200,
    this.TSCmin = 2,
    this.TSCsec = 10,
    this.chime = false,
    this.vibrate = false,
    this.isConnecting = true,
    this.isConfigured = false,
    this.updateDeviceNameSet = false,
    this.updateDeviceConfigurationSet = false,
    this.updateAlertConfigurationSet = false,
    List<DrinkLevel>? data,
  })  : lastDrinkServed = lastDrinkServed ??
            DateTime.parse(
                '2021-10-10 10:10:10'), // Use DateTime.parse to convert string
        data = data ??
            [
              DrinkLevel('11:18 am', 75),
              DrinkLevel('11:17 am', 70),
              DrinkLevel('11:19 am', 62),
              DrinkLevel('11:20 am', 58),
              DrinkLevel('11:21 am', 50),
              DrinkLevel('11:22 am', 40),
              DrinkLevel('11:23 am', 10),
            ];
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceName': deviceName,
      'batteryPercentage': batteryPercentage,
      'levelDrink': levelDrink,
      'lastDrinkServed': lastDrinkServed.toIso8601String(),
      'drinkName': drinkName,
      'DrinkType': DrinkType,
      'DrinkSize': DrinkSize,
      'TSCmin': TSCmin,
      'TSCsec': TSCsec,
      'chime': chime,
      'vibrate': vibrate,
      'isConnecting': isConnecting,
      'isConfigured': isConfigured,
      'updateDeviceNameSet': updateDeviceNameSet,
      'updateDeviceConfigurationSet': updateDeviceConfigurationSet,
      'updateAlertConfigurationSet': updateAlertConfigurationSet,
      'data': data.map((x) => x.toMap()).toList(),
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'],
      deviceName: map['deviceName'],
      batteryPercentage: map['batteryPercentage'],
      levelDrink: map['levelDrink'],
      lastDrinkServed: DateTime.parse(map['lastDrinkServed']),
      drinkName: map['drinkName'],
      DrinkType: map['DrinkType'],
      DrinkSize: map['DrinkSize'],
      TSCmin: map['TSCmin'],
      TSCsec: map['TSCsec'],
      chime: map['chime'],
      vibrate: map['vibrate'],
      isConnecting: map['isConnecting'],
      isConfigured: map['isConfigured'],
      updateDeviceNameSet: map['updateDeviceNameSet'],
      updateDeviceConfigurationSet: map['updateDeviceConfigurationSet'],
      updateAlertConfigurationSet: map['updateAlertConfigurationSet'],
      data:
          List<DrinkLevel>.from(map['data']?.map((x) => DrinkLevel.fromMap(x))),
    );
  }
}
