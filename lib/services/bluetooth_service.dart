import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

// ✅ Renamed from BluetoothService to ESP32BluetoothService
class ESP32BluetoothService {
  static final ESP32BluetoothService _instance = ESP32BluetoothService._internal();
  factory ESP32BluetoothService() => _instance;
  ESP32BluetoothService._internal();

  final _sensorDataController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get sensorDataStream => _sensorDataController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  bool _isConnected = false;
  bool _isScanning = false;

  static const String SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String CHARACTERISTIC_UUID_TX = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  String get deviceName => _device?.name ?? "Not connected";

  Future<List<BluetoothDevice>> scanDevices() async {
  List<BluetoothDevice> devices = [];
  _isScanning = true;

  try {
    // ✅ Check if permissions are granted
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      print("❌ Permissions not granted, cannot scan");
      _isScanning = false;
      return devices; // Return empty list
    }

    print("✅ Permissions granted, starting scan...");
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    await for (var scanResults in FlutterBluePlus.scanResults) {
      for (var scanResult in scanResults) {
        print("📱 Found device: ${scanResult.device.name} (${scanResult.device.id})");
        // Add all devices for testing
        devices.add(scanResult.device);
      }
    }
  } catch (e) {
    print("❌ Scan error: $e");
  }

  _isScanning = false;
  print("🔵 Scan complete, found ${devices.length} devices");
  return devices;
}

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
        _device = device;
        await device.connect(timeout: Duration(seconds: 10));
        _isConnected = true;
        _connectionStatusController.add(true);

        await device.discoverServices();

        // ✅ FIX: Get services from the stream
        final services = await device.services.first;
        for (var service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
            for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID_TX.toLowerCase()) {
                _characteristic = characteristic;
                await characteristic.setNotifyValue(true);
                characteristic.value.listen((value) {
                _handleReceivedData(value);
                });
                print("✅ Connected to ESP32 via BLE");
                return true;
            }
            }
        }
        }

        print("❌ No matching characteristic found");
        await disconnect();
        return false;

    } catch (e) {
        print("❌ Connection error: $e");
        _isConnected = false;
        _connectionStatusController.add(false);
        return false;
    }
  }

  void _handleReceivedData(List<int> data) {
    try {
      String rawData = String.fromCharCodes(data).trim();
      print("📥 Raw data: $rawData");

      if (rawData.startsWith('{') && rawData.endsWith('}')) {
        try {
          Map<String, dynamic> jsonData = jsonDecode(rawData);
          _sensorDataController.add(jsonData);
          print("📊 Parsed: $jsonData");
        } catch (e) {
          print("❌ JSON parse error: $e");
        }
      }
    } catch (e) {
      print("❌ Error parsing data: $e");
    }
  }

  Future<void> sendCommand(String command) async {
    if (_characteristic == null || !_isConnected) {
      print("❌ Not connected to device");
      return;
    }

    try {
      List<int> data = command.codeUnits;
      await _characteristic!.write(data);
      print("📤 Sent: $command");
    } catch (e) {
      print("❌ Failed to send command: $e");
    }
  }

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (e) {
      print("Disconnect error: $e");
    }
    _isConnected = false;
    _device = null;
    _characteristic = null;
    _connectionStatusController.add(false);
  }

Future<bool> _requestPermissions() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    print("🔵 Requesting Bluetooth permissions...");
    
    var status = await Permission.bluetoothConnect.request();
    print("🔵 bluetoothConnect status: $status");
    
    if (status.isDenied) {
      status = await Permission.bluetoothConnect.request();
      print("🔵 bluetoothConnect retry status: $status");
    }
    
    if (status.isGranted) {
      var scanStatus = await Permission.bluetoothScan.request();
      print("🔵 bluetoothScan status: $scanStatus");
      
      var locationStatus = await Permission.locationWhenInUse.request();
      print("🔵 locationWhenInUse status: $locationStatus");
      
      if (scanStatus.isGranted && locationStatus.isGranted) {
        print("✅ All permissions granted!");
        return true;
      } else {
        print("❌ Some permissions denied: scan=$scanStatus, location=$locationStatus");
        return false;
      }
    } else {
      print("❌ Bluetooth connect permission denied: $status");
      return false;
    }
  }
  return true;
}

  void dispose() {
    _sensorDataController.close();
    _connectionStatusController.close();
    disconnect();
  }
}