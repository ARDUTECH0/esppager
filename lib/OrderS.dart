import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pager/Neworder.dart';
import 'package:pager/bluetooth_service.dart';
import 'package:pager/img.dart';
import 'package:pager/initDatabase.dart';
import 'package:sqflite/sqflite.dart';
import 'generated/l10n.dart';

class App extends StatefulWidget {
  final Database database;
  final BluetoothDevice device;

  const App({required this.database, required this.device, Key? key})
      : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  Locale _locale = const Locale('en');

  void _changeLanguage() {
    setState(() {
      _locale = _locale.languageCode == 'en'
          ? const Locale('ar')
          : const Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: _locale,
      home: OrderScreen(
        changeLanguage: _changeLanguage,
        database: widget.database,
        device: widget.device,
      ),
    );
  }
}

class OrderScreen extends StatefulWidget {
  final VoidCallback changeLanguage;
  final Database database;
  final BluetoothDevice device;

  const OrderScreen({
    required this.changeLanguage,
    required this.database,
    required this.device,
    Key? key,
  }) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int _lastOrderNumber = 0;
  late CustomBluetoothService _bluetoothService;
  int _deviceNumber = 0;
  BluetoothCharacteristic? targetCharacteristic;
  String readValue = "";
  bool isConnected = false;
  late StreamSubscription<BluetoothDeviceState> _connectionSubscription;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _bluetoothService = CustomBluetoothService(widget.device);
    _bluetoothService.initialize();
    _getLastOrderNumber();
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    _connectionSubscription.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  Future<void> _getLastOrderNumber() async {
    try {
      List<Map<String, dynamic>> results = await widget.database.rawQuery(
        'SELECT order_number, device_number FROM Orders ORDER BY order_number DESC LIMIT 1',
      );

      if (results.isNotEmpty) {
        int lastOrderNumber =
            int.tryParse(results[0]['order_number'].toString()) ?? 0;
        setState(() {
          _lastOrderNumber = lastOrderNumber;
        });
      } else {
        setState(() {
          _lastOrderNumber = 0;
        });
      }
    } catch (e) {
      print('Error fetching last order number: $e');
      setState(() {
        _lastOrderNumber = 0;
        _deviceNumber = 0;
      });
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    List<Map<String, dynamic>> results;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    if (RegExp(r'^\d+$').hasMatch(query)) {
      results = await getOrdersByOrderNumber(widget.database, query);
    } else {
      results = await getOrdersByPhoneNumber(widget.database, query);
    }

    setState(() {
      _searchResults = results;
      if (results.isNotEmpty) {
        int deviceNumber =
            int.tryParse(results[0]['device_number'].toString()) ?? 0;
        _deviceNumber = deviceNumber;
      }
    });
  }

  Future<void> _deleteOrder(String orderNumber) async {
    await deleteOrderByOrderNumber(widget.database, orderNumber);
    _getLastOrderNumber();
    _search();
  }

  Future<void> _sendDeviceId(String deviceId) async {
    _bluetoothService.writeMessage("SEND $deviceId order call");
  }

  List<Map<String, dynamic>> sortOrders(List<Map<String, dynamic>> orders) {
    orders.sort((a, b) {
      if (isInteger(a['order_number']) && isInteger(b['order_number'])) {
        return int.parse(a['order_number'])
            .compareTo(int.parse(b['order_number']));
      } else {
        return a['order_number'].compareTo(b['order_number']);
      }
    });
    return orders;
  }

  bool isInteger(String s) {
    return int.tryParse(s) != null;
  }

  void _clearTextFields() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return isTablet ? buildTabletLayout(context) : buildMobileLayout(context);
  }

  Widget buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFe0e0e0),
              child: Stack(
                children: [
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: widget.changeLanguage,
                          child: Text(
                            S.of(context).changeLanguage,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DeviceManagementScreen(
                                        bluetoothService: _bluetoothService,
                                      )),
                              (route) => true,
                            );
                          },
                          icon: const Icon(
                            Icons.settings,
                            size: 32,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              IconManager.Ts, // Ensure this path is valid
                              width: 150,
                              height: 150,
                            ),
                            Text(
                              _deviceNumber.toString(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              S.of(context).invoiceOrPhoneNumber,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 200,
                              color: Colors.white,
                              child: TextField(
                                controller: _searchController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 24),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 70,
                              width: 200,
                              child: ElevatedButton(
                                onPressed: _search,
                                child: Text(
                                  S.of(context).call,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _searchResults.isNotEmpty
                        ? Container(
                            color: Colors.white,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final order = _searchResults[index];
                                return ListTile(
                                  title: Text(
                                    '${S.of(context).order}: ${order['order_number']}, ${S.of(context).device}: ${order['device_number']}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  subtitle: Text(
                                    '${S.of(context).phone}: ${order['phone_number']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteOrder(
                                        order['order_number'].toString()),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFe0e0e0),
              child: Stack(
                children: [
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: widget.changeLanguage,
                          child: Text(
                            S.of(context).changeLanguage,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DeviceManagementScreen(
                                        bluetoothService: _bluetoothService,
                                      )),
                              (route) => true,
                            );
                          },
                          icon: const Icon(
                            Icons.settings,
                            size: 28,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Add notification logic here
                          },
                          icon: const Icon(
                            Icons.notifications,
                            size: 28,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              IconManager.Ts, // Ensure this path is valid
                              width: 100,
                              height: 100,
                            ),
                            Text(
                              _deviceNumber.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          S.of(context).invoiceOrPhoneNumber,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          color: Colors.white,
                          child: TextField(
                            controller: _searchController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 50,
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: ElevatedButton(
                            onPressed: _search,
                            child: Text(
                              S.of(context).call,
                              style: const TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _searchResults.isNotEmpty
                            ? Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                color: Colors.white,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final order = _searchResults[index];
                                    return ListTile(
                                      title: Text(
                                        '${S.of(context).order}: ${order['order_number']}, ${S.of(context).device}: ${order['device_number']}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      subtitle: Text(
                                        '${S.of(context).phone}: ${order['phone_number']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _deleteOrder(
                                                order['order_number']
                                                    .toString()),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.call,
                                                color: Colors.green),
                                            onPressed: () => _sendDeviceId(
                                                order['device_number']
                                                    .toString()),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
