import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:pager/OrderS.dart'; // Ensure this is the correct import for your screen
import 'package:pager/initDatabase.dart';
import 'package:sqflite/sqflite.dart';

class FindDevicesScreen extends StatefulWidget {
  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  late Database _database;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _database = await initDatabase();
    setState(() {}); // Refresh the UI once the database is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await FlutterBlue.instance.startScan(timeout: Duration(seconds: 4));
          // Optionally refresh database data or other UI updates
        },
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => ListTile(
                            title: Text(
                                d.name.isNotEmpty ? d.name : 'Unnamed Device'),
                            subtitle: Text(d.id.toString()),
                            trailing: StreamBuilder<BluetoothDeviceState>(
                              stream: d.state,
                              initialData: BluetoothDeviceState.disconnected,
                              builder: (c, snapshot) {
                                if (snapshot.data ==
                                    BluetoothDeviceState.connected) {
                                  return TextButton(
                                    child: Text('OPEN'),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => App(
                                          database: _database,
                                          device: d,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return Text(snapshot.data.toString());
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((r) => ScanResultTile(
                            result: r,
                            onTap: () async {
                              try {
                                await r.device.connect();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => App(
                                      database: _database,
                                      device: r.device,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                print("Error connecting to device: $e");
                              }
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
              child: Icon(Icons.search),
              onPressed: () async {
                await FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4));
              },
            );
          }
        },
      ),
    );
  }
}

class ScanResultTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const ScanResultTile({Key? key, required this.result, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(result.device.name.isNotEmpty
          ? result.device.name
          : result.device.id.toString()),
      subtitle: Text('RSSI: ${result.rssi}'),
      onTap: onTap,
    );
  }
}
