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
  BluetoothCharacteristic? _characteristic; // TX (Read/Notify)
  BluetoothCharacteristic? _writeCharacteristic; // RX (Write)
  bool _isConnected = false;
  bool _isScanning = false;

  static const String SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String CHARACTERISTIC_UUID_RX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // Mobile -> ESP
  static const String CHARACTERISTIC_UUID_TX = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // ESP -> Mobile

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  String get deviceName => _device?.name ?? "Not connected";

  Future<List<BluetoothDevice>> scanDevices() async {
    List<BluetoothDevice> devices = [];
    _isScanning = true;

    try {
      // Check if permissions are granted
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print("❌ Permissions not granted, cannot scan");
        _isScanning = false;
        return devices;
      }

      // Check if Bluetooth is on
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        print("❌ Bluetooth is not turned on");
        _isScanning = false;
        return devices;
      }

      print("✅ Permissions granted, starting scan...");

      // Collect devices from scan results using a Set to avoid duplicates
      final Set<String> seenIds = {};

      // Listen to scan results and collect devices
      final subscription = FlutterBluePlus.onScanResults.listen((results) {
        for (var r in results) {
          if (!seenIds.contains(r.device.remoteId.str)) {
            seenIds.add(r.device.remoteId.str);
            devices.add(r.device);
            print("📱 Found device: ${r.device.platformName} (${r.device.remoteId})  RSSI: ${r.rssi}");
          }
        }
      });

      // Start scan — no service filter so ALL nearby BLE devices are shown
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));

      // Wait for scan to fully complete
      await FlutterBluePlus.isScanning.where((val) => val == false).first;

      // Cancel subscription
      await subscription.cancel();

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
      print("🔵 Connecting to ${device.platformName} (${device.remoteId})...");
      await device.connect(timeout: const Duration(seconds: 10));
      _isConnected = true;
      _connectionStatusController.add(true);

      print("🔵 Connected! Discovering services...");
      // Use the return value of discoverServices() directly
      List<BluetoothService> services = await device.discoverServices();

      // Debug: log ALL services and characteristics the ESP32 exposes
      print("🔵 Found ${services.length} services:");
      for (var service in services) {
        print("  📦 Service: ${service.uuid}");
        for (var c in service.characteristics) {
          print("    🔹 Characteristic: ${c.uuid}  properties: ${c.properties}");
        }
      }

      // Search for the Nordic UART Service (or any matching service)
      for (var service in services) {
        final sUuid = service.uuid.str.toLowerCase();
        if (sUuid == SERVICE_UUID.toLowerCase() || sUuid.contains("6e400001")) {
          for (var characteristic in service.characteristics) {
            final cUuid = characteristic.uuid.str.toLowerCase();
            
            // TX characteristic (ESP -> Mobile)
            if (cUuid == CHARACTERISTIC_UUID_TX.toLowerCase() || cUuid.contains("6e400003")) {
              _characteristic = characteristic; // Read char
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  _handleReceivedData(value);
                }
              });
              print("✅ Listening to ESP32 TX: ${characteristic.uuid}");
            }
            
            // RX characteristic (Mobile -> ESP)
            if (cUuid == CHARACTERISTIC_UUID_RX.toLowerCase() || cUuid.contains("6e400002")) {
              _writeCharacteristic = characteristic; // Write char
              print("✅ Found ESP32 RX (Write): ${characteristic.uuid}");
            }
          }
          
          if (_characteristic != null) return true;
        }
      }

      // If Nordic UART not found, try to find ANY characteristic with notify and write
      print("⚠️ Nordic UART service not found, looking for any notify/write characteristic...");
      for (var service in services) {
        // Skip generic BLE services (GAP, GATT, Device Info)
        final sUuid = service.uuid.str.toLowerCase();
        if (sUuid.startsWith("00001800") || sUuid.startsWith("00001801") || sUuid.startsWith("0000180a")) {
          continue;
        }
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            _characteristic = characteristic;
            await characteristic.setNotifyValue(true);
            characteristic.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                _handleReceivedData(value);
              }
            });
            print("✅ Connected via fallback — notify char: ${characteristic.uuid}");
          }
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            print("✅ Connected via fallback — write char: ${characteristic.uuid}");
          }
        }
        if (_characteristic != null) return true;
      }

      print("❌ No compatible characteristic found on this device");
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
    if (_writeCharacteristic == null || !_isConnected) {
      print("❌ Not connected or write characteristic not found");
      return;
    }

    try {
      List<int> data = command.codeUnits;
      await _writeCharacteristic!.write(data, withoutResponse: _writeCharacteristic!.properties.writeWithoutResponse);
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