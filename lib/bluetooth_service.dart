// bluetooth_service.dart

import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';

class CustomBluetoothService {
  final BluetoothDevice device;
  BluetoothCharacteristic? targetCharacteristic;
  bool isConnected = false;
  late StreamSubscription<BluetoothDeviceState> _connectionSubscription;

  CustomBluetoothService(this.device);

  Future<void> initialize() async {
    _connectionSubscription = device.state.listen((state) {
      isConnected = state == BluetoothDeviceState.connected;
      if (isConnected) {
        discoverServices();
      }
    });
    connectToDevice();
  }

  Future<void> connectToDevice() async {
    try {
      await device.connect(autoConnect: false);
    } catch (e) {
      if (e.toString() != 'already_connected') {
        print("Error connecting to device: $e");
      }
    }
  }

  Future<void> discoverServices() async {
    if (isConnected) {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() ==
              "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
            targetCharacteristic = characteristic;
          }
        }
      }
    }
  }

  Future<void> writeMessage(String message) async {
    if (targetCharacteristic != null) {
      try {
        await targetCharacteristic!.write(message.codeUnits);
        readMessage();
      } catch (e) {
        print("Error writing to characteristic: $e");
      }
    } else {
      print("Characteristic is null");
    }
  }

  Future<void> readMessage() async {
    if (targetCharacteristic != null) {
      try {
        var value = await targetCharacteristic!.read();
        print("Received value: ${String.fromCharCodes(value)}");
      } catch (e) {
        print("Error reading from characteristic: $e");
      }
    }
  }

  void dispose() {
    _connectionSubscription.cancel();
    device.disconnect();
  }
}
