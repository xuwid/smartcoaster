import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartcoaster/provider/provider.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  _DeviceControlScreenState createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  // State variable to hold the selected drink type
  String? _selectedDrinkType; // Initialized to null to show hint initially

  // List of drink type options
  final List<String> _drinkTypes = ['Cup', 'Glass', 'Jug'];

  // Controllers for text fields
  final TextEditingController _drinkName = TextEditingController();
  final TextEditingController _drinkSizeController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _secController = TextEditingController();

  // State variables for switches
  bool valVib = false;
  bool valChime = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and state variables with saved data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
      final currentDevice = deviceProvider.currentDevice;

      if (currentDevice != null) {
        // Initialize TextEditingControllers with saved values
        if (currentDevice.updateDeviceNameSet) {
          _deviceNameController.text = currentDevice.deviceName ?? '';
        }
        if (currentDevice.updateDeviceConfigurationSet) {
          _drinkSizeController.text = currentDevice.DrinkSize != null
              ? currentDevice.DrinkSize.toString()
              : '';
          _selectedDrinkType = currentDevice.DrinkType;
        }
        if (currentDevice.updateAlertConfigurationSet) {
          _minController.text = currentDevice.TSCmin != null
              ? currentDevice.TSCmin.toString()
              : '';
          _secController.text = currentDevice.TSCsec != null
              ? currentDevice.TSCsec.toString()
              : '';
        }

        // Initialize selected drink type

        // Initialize switch values
        setState(() {
          valVib = currentDevice.vibrate;
          valChime = currentDevice.chime;
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _deviceNameController.dispose();
    _drinkSizeController.dispose();
    _minController.dispose();
    _secController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the provider
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final currentDevice = deviceProvider.currentDevice;

    // Update switch values if they change externally
    if (currentDevice != null) {
      if (valVib != currentDevice.vibrate) {
        valVib = currentDevice.vibrate;
      }
      if (valChime != currentDevice.chime) {
        valChime = currentDevice.chime;
      }
      // Update the selected drink type if it changes
      if (_selectedDrinkType != currentDevice.DrinkType) {
        _selectedDrinkType = currentDevice.DrinkType;
      }
    }

    final OutlineInputBorder enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(
        color: Colors.grey, // Grey border when not focused
        width: 1,
      ),
    );

    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(
        color: Colors.blue, // Blue border when focused
        width: 1,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Device Controls',
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        forceMaterialTransparency: true,
        backgroundColor: Colors.grey[850],
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                buildLabelWithAsterisk("Device Name*"),
                const SizedBox(height: 10),

                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _deviceNameController,
                    style: const TextStyle(color: Colors.white),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Smart Coaster 1',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: enabledBorder,
                      enabledBorder: enabledBorder,
                      focusedBorder: focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Must be at least 6 characters.',
                  style: GoogleFonts.robotoMono(
                      color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                buildLabelWithAsterisk("Drink Name*"),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _drinkName,
                    style: const TextStyle(color: Colors.white),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Drink Name',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: enabledBorder,
                      enabledBorder: enabledBorder,
                      focusedBorder: focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _deviceNameController.text =
                          _deviceNameController.text.trim();
                      // Close the keyboard after this
                      FocusScope.of(context).unfocus();

                      if (_deviceNameController.text.length < 6 ||
                          _drinkName.text == '') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Characters must be at least 6 characters or Fill the required fields')),
                        );
                      } else {
                        deviceProvider
                            .setCurrentDeviceName(_deviceNameController.text);
                        deviceProvider.setcurrentDrinkName(_drinkName.text);
                        deviceProvider.updateDeviceNameSet(true);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Device Name changed')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Update Device Name',
                      style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Divider(color: Colors.grey[700], height: 40),

                // Device Configuration Label
                const Text(
                  'Device Configuration',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),

                // Drink Type Label with Asterisk
                buildLabelWithAsterisk("Drink Type*"),
                const SizedBox(height: 10),

                // Drink Type Field with Dropdown Button
                SizedBox(
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showDrinkTypeModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Display selected drink type or hint
                          Text(
                            _selectedDrinkType ?? "Select Option",
                            style: TextStyle(
                              color: _selectedDrinkType != null
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Drink Size Input with Asterisk
                buildLabelWithAsterisk('Drink Size (ml)*'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _drinkSizeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: '150 ml',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: enabledBorder,
                      enabledBorder: enabledBorder,
                      focusedBorder: focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Update Device Configuration Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      int? drinkSize = int.tryParse(_drinkSizeController.text);
                      if (drinkSize == null || _selectedDrinkType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Fill the required fields')),
                        );
                      } else {
                        deviceProvider.setcurrentDrinkSize(drinkSize);
                        deviceProvider.setcurrentDrinkType(_selectedDrinkType!);
                        deviceProvider.updateDeviceConfigurationSet(true);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Device Configuration Updated')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Update Device Configuration',
                      style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Divider(color: Colors.grey[700], height: 40),

                // Device Alert Configuration Label
                const Text(
                  'Device Alert Configuration',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),

                // Time Since Empty Input
                buildLabelWithAsterisk("Time since empty*"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextField(
                              controller: _minController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: '4',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: enabledBorder,
                                enabledBorder: enabledBorder,
                                focusedBorder: focusedBorder,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0.0, horizontal: 10.0),
                              ),
                            ),
                            const Positioned(
                              right: 10, // Position it at the right end
                              child: Text(
                                'min',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextField(
                              controller: _secController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: '10',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: enabledBorder,
                                enabledBorder: enabledBorder,
                                focusedBorder: focusedBorder,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0.0, horizontal: 10.0),
                              ),
                            ),
                            const Positioned(
                              right: 10, // Position it at the right end
                              child: Text(
                                'sec',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Instruction Text
                Text(
                  'Use minutes and seconds combined to set time since empty.',
                  style: GoogleFonts.robotoMono(
                      color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Vibrate on Alert Toggle with Asterisk
                _buildSwitchRow('Vibrate on alert*', valVib, (value) {
                  setState(() {
                    valVib = value; // Update the state variable
                    deviceProvider.setcurrentDevicevibrate(value);
                  });
                }),
                const SizedBox(height: 20),

                // Chime on Alert Toggle with Asterisk
                _buildSwitchRow('Chime on alert*', valChime, (value) {
                  setState(() {
                    valChime = value; // Update the state variable
                    deviceProvider.setcurrentDevicechime(value);
                  });
                }),
                const SizedBox(height: 20),

                // Update Alert Configuration Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      int? min = int.tryParse(_minController.text);
                      int? sec = int.tryParse(_secController.text);
                      if (sec == null || min == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Fill the required fields')),
                        );
                      } else {
                        deviceProvider.updateAlertConfigurationSet(true);
                        deviceProvider.setcurrentDevicemin(min);
                        deviceProvider.setcurrentDevicesec(sec);
                        await deviceProvider.updateTime(
                            currentDevice!.id, min * 60 + sec);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Alert Configuration Updated')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Update Alert Configuration',
                      style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build labels with an asterisk in red.
  Widget buildLabelWithAsterisk(String label) {
    List<String> parts = label.split('*');

    return RichText(
      text: TextSpan(
        text: parts[0],
        style: GoogleFonts.robotoMono(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        children: parts.length > 1
            ? [
                const TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : [],
      ),
    );
  }

  /// Builds a switch row with the label's asterisk in red if present.
  Widget _buildSwitchRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildLabelWithAsterisk(label),
        Switch(
          value: value, // Use the passed state variable
          onChanged: onChanged, // Use the passed function to update the state
          activeColor: Colors.blue,
        ),
      ],
    );
  }

  /// Displays a modal for selecting drink types.
  void _showDrinkTypeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.grey[850],
          child: ListView.builder(
            itemCount: _drinkTypes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  _drinkTypes[index],
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    _selectedDrinkType = _drinkTypes[index];
                  });
                  Provider.of<DeviceProvider>(context, listen: false)
                      .setcurrentDrinkType(
                          _selectedDrinkType!); // Save selection
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}
