import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smartcoaster/model/model.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:smartcoaster/model/mqtt.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceProvider with ChangeNotifier {
  List<Device> _devices = [
//    Device(
    // id: 'id',
    // isConfigured: false,
    // isConnecting: true,
    // levelDrink: 60,
    // deviceName: 'Dummy Data'),
  ];
  List<BluetoothDevice> connectedDevices = [];

  Device? _currentDevice;
  final Map<String, Timer> _pingTimers = {};

  List<Device> get devices => _devices;
  Device? get currentDevice => _currentDevice;
  List<BluetoothDevice> get connectedDevicesList => connectedDevices;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> saveDevicesToLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> deviceList =
        _devices.map((device) => json.encode(device.toMap())).toList();
    await prefs.setStringList('devices', deviceList);
    // print('Devices saved to local storage');
  }

  Future<void> loadDevicesFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? deviceList = prefs.getStringList('devices');
    if (deviceList != null) {
      _devices = deviceList.map((device) {
        Map<String, dynamic> deviceMap = json.decode(device);
        return Device.fromMap(deviceMap);
      }).toList();
      notifyListeners();
      //    print('Devices loaded from local storage');
    }
  }

  final MQTTService mqttService = MQTTService(); // MQTT servic
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  DeviceProvider() {
    loadDevicesFromLocal();
    _initNotifications();
    _subscribeToTopics();
  }
  void _subscribeToTopics() async {
    await mqttService.connect();
    for (var device in _devices) {
      if (device.id != null) {
        // Subscribe to /mac_address/ping
        mqttService.subscribeToTopic('/${device.id}/ping');
        mqttService.subscribeToTopic('/${device.id}/update');

        mqttService.publishJsonToTopic('/${device.id}/update',
            {'action': 'time', 'value': device.TSCmin * 60 + device.TSCsec});

        // Subscribe to /mac_address/alert
        mqttService.subscribeToTopic('/${device.id}/alert');
      }
    }

    // Listen for incoming messages
    mqttService.onMessage = (topic, payload) {
      final message = String.fromCharCodes(payload);
      print('Received message: $message from topic: $topic');
      _handleIncomingMessage(topic, message);
    };
  }

  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
    saveDevicesToLocal();
    _subscribeToTopics();
  }

  void _handleIncomingMessage(String topic, String message) {
    //Now topic will be /mac_address/ping

    final deviceId = topic.split('/')[1];
    final device = _devices.firstWhere((d) => d.id == deviceId);

    final parsedMessage = _parseMessage(message);
    if (parsedMessage['action'] == 'ping') {
      // Handle ping action

      print('Ping received for device: $deviceId');
      // Handle ping action
      print('Ping received for device: $deviceId');

      // Reset the ping timer if we received a ping
      _resetPingTimer(deviceId);

      // Update device's connecting status
      device.isConnecting = true;
      notifyListeners();
      saveDevicesToLocal();
    } else if (parsedMessage['action'] == 'level') {
      // Handle level action, update device level
      final int level = parsedMessage['value'];
      device.levelDrink = level;

      // Get current time in the format 'hh:mm am/pm'
      final String currentTime = _getCurrentTime();

      if (level == 100) {
        device.lastDrinkServed = DateTime.now();
      }

      // Insert the new level at the first position of the list
      device.data.insert(0, DrinkLevel(currentTime, level));
      if (device.data.length > 1000) {
        device.data.removeLast();
      }

      // Notify listeners for UI update
      notifyListeners();
      saveDevicesToLocal();
    } else if (parsedMessage['action'] == 'alert') {
      // Trigger alert notification
      print("device chime and vibrate");
      print(device.chime);
      print(device.vibrate);
      bool chime = device.chime;
      bool vibrate = device.vibrate;
      _showNotification(
          'Alert',
          'Waiter call received from device: ${device.deviceName}',
          chime,
          vibrate);
    } else if (parsedMessage['action'] == 'battery level') {
      // Handle battery level update

      final int battery = parsedMessage['value'];
      device.batteryPercentage = battery.toDouble();
      notifyListeners();
      saveDevicesToLocal();
      print("Battery level received for device: $deviceId");
      print("Battery level: $battery%");
      print(device.batteryPercentage);
      ;
    }
    //
    print('Device not found for incoming message');
  }

  // Helper function to get current time in 'hh:mm am/pm' format
  String _getCurrentTime() {
    final now = DateTime.now();

    // Converting to 12-hour format
    int hour = now.hour;
    String period = hour >= 12 ? 'pm' : 'am';

    hour = hour % 12;
    if (hour == 0) hour = 12; // Handle the case of 12:00 am/pm

    String minute = now.minute.toString().padLeft(2, '0');

    return '$hour:$minute $period';
  }

  Map<String, dynamic> _parseMessage(String message) {
    return Map<String, dynamic>.from(jsonDecode(message));
  }

  void setCurrentDrinkName(String drinkName) {
    _currentDevice!.drinkName = drinkName;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
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
            setCurrentDeviceId(jsonResponse["v"]);

            print(currentDevice!.deviceName);
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

  void _resetPingTimer(String deviceId) {
    // Cancel the previous timer if any
    _pingTimers[deviceId]?.cancel();

    // Set a new timer to check the connection status after 10 seconds
    _pingTimers[deviceId] = Timer(const Duration(seconds: 20), () {
      final device = _devices.firstWhere((d) => d.id == deviceId);
      if (device.isConnecting) {
        // If no ping was received in the last 10 seconds, set isConnecting to false
        device.isConnecting = false;
        device.isConfigured = false;
        print(
            'Device $deviceId is no longer connecting. WiFi might be disconnected.');
        notifyListeners(); // Notify listeners of the change
        saveDevicesToLocal();
      }
    });
  }

  Future<void> _initNotifications() async {
    _requestNotificationPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        const InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _createNotificationChannel(
      bool playSound, bool enableVibration) async {
    // Define a new unique channel ID for each notification to ensure it's dynamically created.
    final String channelId =
        'alert_channel_${DateTime.now().millisecondsSinceEpoch}';

    // Create a new notification channel with dynamic sound and vibration settings
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId, // Unique channel ID
      'Alert Notifications', // Name
      description: 'Notifications for alert messages', // Description
      importance: Importance.max, // Set importance level
      playSound: playSound, // Dynamic sound setting
      enableVibration: enableVibration, // Dynamic vibration setting
    );

    // Register the notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _showNotification(
      String title, String body, bool chime, bool vibrate) async {
    // Set the dynamic properties for sound and vibration
    bool enableVibration = vibrate; // Enable vibration if vibrate is true
    bool playSound = chime; // Enable sound if chime is true

    // Create a new notification channel with updated settings
    await _createNotificationChannel(playSound, enableVibration);

    // Set up the notification details
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      // Use the new channel ID created in _createNotificationChannel
      'alert_channel_${DateTime.now().millisecondsSinceEpoch}',
      'Alert Notifications', // Channel name
      channelDescription: 'Notifications for alert messages',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: enableVibration, // Dynamically enable/disable vibration
      playSound: playSound, // Dynamically enable/disable sound
      showWhen: true, // Show the notification time
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show the notification with the dynamic settings
    await flutterLocalNotificationsPlugin.show(
      2, // Notification ID
      title, // Notification title
      body, // Notification body
      platformChannelSpecifics, // Notification details
      payload: 'item id 2', // Optional payload
    );
  }

  void send() async {}
  void getDeviceById(String id) {
    _currentDevice = _devices.firstWhere((device) => device.id == id);
    notifyListeners();
    saveDevicesToLocal();
  }

  void setCurrentDeviceId(String id) {
    currentDevice!.id = id;
    notifyListeners();
    saveDevicesToLocal();
  }

  void setConnectedDevicesList(List<BluetoothDevice> devices) {
    connectedDevices = devices;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setCurrentDeviceName(String deviceName) {
    _currentDevice!.deviceName = deviceName;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentBatteryPercentage(double batteryPercentage) {
    _currentDevice!.batteryPercentage = batteryPercentage;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentLevelDrink(int levelDrink) {
    _currentDevice!.levelDrink = levelDrink;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void adddevicetodevices(Device device) {
    _devices.add(device);
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentLastDrinkServed(DateTime lastDrinkServed) {
    _currentDevice!.lastDrinkServed = lastDrinkServed;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentDrinkName(String drinkName) {
    _currentDevice!.drinkName = drinkName;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentDrinkType(String DrinkType) {
    _currentDevice!.DrinkType = DrinkType;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentDrinkSize(int DrinkSize) {
    _currentDevice!.DrinkSize = DrinkSize;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentDevicemin(int min) {
    _currentDevice!.TSCmin = min;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentDeviceConfiguration(bool isConfigured) {
    _currentDevice!.isConfigured = isConfigured;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentDeviceConnecting(bool isConnecting) {
    _currentDevice!.isConnecting = isConnecting;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentDevicesec(int sec) {
    _currentDevice!.TSCsec = sec;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentDevicevibrate(bool vibrate) {
    _currentDevice!.vibrate = vibrate;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setcurrentDevicechime(bool chime) {
    _currentDevice!.chime = chime;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void setCurrentDevice(Device device) {
    _currentDevice = device;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void updateDeviceNameSet(bool updateDeviceNameSet) {
    _currentDevice!.updateDeviceNameSet = updateDeviceNameSet;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  Future<void> updateTime(String? id, int time) async {
    print('Updating time for device: $id');

    // Attempt to subscribe and publish
    if (mqttService.client.connectionStatus?.state ==
        MqttConnectionState.connected) {
      // If connected, proceed to subscribe and publish
      mqttService.subscribeToTopic('/$id/update');
      mqttService
          .publishJsonToTopic('/$id/update', {'action': 'time', 'value': time});
    } else {
      // If not connected, log an error message
      print('Failed to update time for device: $id. Client is not connected.');

      try {
        // Attempt to reconnect
        print('Attempting to reconnect to broker...');
        await mqttService.connect();

        // Check if the reconnection was successful
        if (mqttService.client.connectionStatus?.state ==
            MqttConnectionState.connected) {
          print('Reconnected to broker');

          // Now, attempt to subscribe and publish the message again
          mqttService.subscribeToTopic('/$id/update');
          mqttService.publishJsonToTopic(
              '/$id/update', {'action': 'time', 'value': time});
        } else {
          print(
              'Reconnection failed - Status: ${mqttService.client.connectionStatus?.state}');
        }
      } catch (e) {
        // Handle any errors that occur during the reconnect attempt
        print('Reconnection error: $e');
      }
    }

    // Notify listeners at the end
    notifyListeners();
  }

  void updateDeviceConfigurationSet(bool updateDeviceConfigurationSet) {
    _currentDevice!.updateDeviceConfigurationSet = updateDeviceConfigurationSet;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }

  void updateAlertConfigurationSet(bool updateAlertConfigurationSet) {
    _currentDevice!.updateAlertConfigurationSet = updateAlertConfigurationSet;
    notifyListeners(); // Notify listeners of the change
    saveDevicesToLocal();
  }
}
