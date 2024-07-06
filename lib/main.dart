import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Weather Station',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherStationScreen(),
    );
  }
}

class WeatherStationScreen extends StatefulWidget {
  @override
  _WeatherStationScreenState createState() => _WeatherStationScreenState();
}

class _WeatherStationScreenState extends State<WeatherStationScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;
  String weatherData = 'Searching for devices...';

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name == 'ESP32_WeatherStation') {
          device = r.device;
          connectToDevice();
          break;
        }
      }
    });
  }

  void connectToDevice() async {
    if (device == null) return;
    await device!.connect();
    discoverServices();
  }

  void discoverServices() async {
    if (device == null) return;
    List<BluetoothService> services = await device!.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == "00002a6e-0000-1000-8000-00805f9b34fb") {
          characteristic = c;
          setNotification();
          break;
        }
      }
    }
  }

  void setNotification() async {
    if (characteristic == null) return;
    await characteristic!.setNotifyValue(true);
    characteristic!.value.listen((value) {
      setState(() {
        weatherData = String.fromCharCodes(value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP32 Weather Station'),
      ),
      body: Center(
        child: Text(
          weatherData,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
