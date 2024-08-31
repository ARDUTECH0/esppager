import 'package:flutter/material.dart';
import 'package:pager/OrderS.dart';
import 'package:pager/WebSocket.dart';
import 'package:sqflite/sqflite.dart';
import 'initDatabase.dart';

final WebSocketService webSocketService = WebSocketService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await initDatabase();

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final Database database;

  MyApp({required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: App(
        database: database,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Database database;

  HomeScreen({required this.database});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _deviceNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  int _lastOrderNumber = 0;

  @override
  void initState() {
    super.initState();
    _getLastOrderNumber();
  }

  Future<void> _getLastOrderNumber() async {
    try {
      List<Map<String, dynamic>> results = await widget.database.rawQuery(
        'SELECT MAX(CAST(order_number AS INTEGER)) as max_order FROM Orders',
      );

      if (results.isNotEmpty && results[0]['max_order'] != null) {
        int maxOrder = results[0]['max_order'];
        setState(() {
          _lastOrderNumber = maxOrder;
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
      });
    }
  }

  Future<void> _insertOrder() async {
    _lastOrderNumber++;

    await insertOrder(
      widget.database,
      _lastOrderNumber.toString(),
      _deviceNumberController.text,
      _phoneNumberController.text,
    );
    _clearTextFields();
    _search(); // Refresh search results after insertion
  }

  void _clearTextFields() {
    _deviceNumberController.clear();
    _phoneNumberController.clear();
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

    // Check if the query is a number (order number) or not
    if (RegExp(r'^\d+$').hasMatch(query)) {
      // If the input is purely numeric, search by order number
      results = await getOrdersByOrderNumber(widget.database, query);
    } else {
      // If the input is not purely numeric, search by phone number
      results = await getOrdersByPhoneNumber(widget.database, query);
    }

    setState(() {
      _searchResults = results;
    });
  }

  Future<void> _deleteOrder(String orderNumber) async {
    await deleteOrderByOrderNumber(widget.database, orderNumber);
    _getLastOrderNumber(); // Refresh last order number after deletion
    _search(); // Refresh search results after deletion
  }

  List<Map<String, dynamic>> sortOrders(List<Map<String, dynamic>> orders) {
    orders.sort((a, b) {
      // Check if order_number can be parsed to integer
      if (isInteger(a['order_number']) && isInteger(b['order_number'])) {
        return int.parse(a['order_number'])
            .compareTo(int.parse(b['order_number']));
      } else {
        // Fallback sorting by default order or other criteria
        return a['order_number'].compareTo(b['order_number']);
      }
    });
    return orders;
  }

  bool isInteger(String s) {
    if (s == null) {
      return false;
    }
    return int.tryParse(s) != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Management'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Auto-generated order number label
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'Next Order Number: ${_lastOrderNumber + 1}',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
            TextField(
              controller: _deviceNumberController,
              decoration: InputDecoration(labelText: 'Device Number'),
            ),
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            ElevatedButton(
              onPressed: _insertOrder,
              child: Text('Insert Order'),
            ),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  labelText: 'Search by Phone Number or Order Number'),
            ),
            ElevatedButton(
              onPressed: _search,
              child: Text('Search'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final order = _searchResults[index];
                  return ListTile(
                    title: Text('Order Number: ${order['order_number']}'),
                    subtitle: Text(
                        'Device Number: ${order['device_number']}, Date: ${order['timestamp']}, Phone: ${order['phone_number']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteOrder(order['order_number']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> insertOrder(Database db, String orderNumber, String deviceNumber,
    String phoneNumber) async {
  await db.insert(
    'Orders',
    {
      'order_number': orderNumber,
      'device_number': deviceNumber,
      'phone_number': phoneNumber,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Map<String, dynamic>>> getOrdersByPhoneNumber(
    Database db, String phoneNumber) async {
  return await db.query(
    'Orders',
    where: 'phone_number = ?',
    whereArgs: [phoneNumber],
  );
}

Future<List<Map<String, dynamic>>> getOrdersByOrderNumber(
    Database db, String orderNumber) async {
  return await db.query(
    'Orders',
    where: 'order_number = ?',
    whereArgs: [orderNumber],
  );
}

Future<void> deleteOrderByOrderNumber(Database db, String orderNumber) async {
  await db.delete(
    'Orders',
    where: 'order_number = ?',
    whereArgs: [orderNumber],
  );
}

Future<void> insertOrUpdateDevice(Database db, int id, String status) async {
  try {
    // Check if a device with the given ID already exists
    final existingDevice = await db.query(
      'Devices',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existingDevice.isNotEmpty) {
      // Device exists, so update it
      await db.update(
        'Devices',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      // Device does not exist, so insert it
      await db.insert(
        'Devices',
        {'id': id, 'status': status},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  } catch (e) {
    print('Error inserting or updating device: $e');
    rethrow;
  }
}
