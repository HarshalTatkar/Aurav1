import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/bluetooth_provider.dart';
import '../services/bluetooth_service.dart'; // ✅ Add this import
import '../core/theme.dart';

class BluetoothConnectScreen extends ConsumerStatefulWidget {
  const BluetoothConnectScreen({super.key});

  @override
  ConsumerState<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends ConsumerState<BluetoothConnectScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(bluetoothListenerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(bluetoothConnectionProvider);
    final deviceName = ref.watch(bluetoothDeviceNameProvider);
    final devices = ref.watch(bluetoothDevicesProvider);
    final isScanning = ref.watch(bluetoothScanningProvider);
    final btService = ref.watch(bluetoothServiceProvider);

    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: AppBar(
        title: Text('Connect ESP32'),
        backgroundColor: AuraColors.background,
        elevation: 0,
        actions: [
          if (isConnected)
            IconButton(
              icon: Icon(Icons.bluetooth_disabled, color: Colors.red),
              onPressed: () => btService.disconnect(),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isScanning ? null : _scanDevices,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isConnected ? AuraColors.healthy.withAlpha(20) : AuraColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnected ? AuraColors.healthy : AuraColors.textTertiary,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    color: isConnected ? AuraColors.healthy : AuraColors.textTertiary,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: isConnected ? AuraColors.healthy : AuraColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isConnected ? deviceName : 'Scan for ESP32 devices',
                          style: TextStyle(
                            color: AuraColors.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Scan Button
            if (!isConnected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isScanning ? null : _scanDevices,
                  icon: isScanning
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.bluetooth_searching),
                  label: Text(isScanning ? 'Scanning...' : 'Scan for ESP32'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // Device List
            if (!isConnected && devices.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.bluetooth, color: AuraColors.techBlue),
                        title: Text(device.name.isEmpty ? 'Unknown' : device.name),
                        subtitle: Text(device.id.id),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(device, btService),
                          child: Text('Connect'),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // No devices found
            if (!isConnected && !isScanning && devices.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_searching, size: 64, color: AuraColors.textTertiary),
                      SizedBox(height: 16),
                      Text(
                        'No devices found',
                        style: TextStyle(color: AuraColors.textSecondary, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Make sure your ESP32 is powered on',
                        style: TextStyle(color: AuraColors.textTertiary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _scanDevices() async {
    final btService = ref.read(bluetoothServiceProvider);
    ref.read(bluetoothScanningProvider.notifier).state = true;
    ref.read(bluetoothDevicesProvider.notifier).state = [];

    final devices = await btService.scanDevices();
    ref.read(bluetoothDevicesProvider.notifier).state = devices;
    ref.read(bluetoothScanningProvider.notifier).state = false;
  }

  // ✅ Use ESP32BluetoothService type
  void _connectToDevice(BluetoothDevice device, ESP32BluetoothService service) async {
    ref.read(bluetoothDeviceNameProvider.notifier).state = device.name;
    final success = await service.connectToDevice(device);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed'), backgroundColor: Colors.red),
      );
    }
  }
}