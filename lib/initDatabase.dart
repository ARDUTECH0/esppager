import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Initialize the database
Future<Database> initDatabase() async {
  var databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'orders3.db');

  return await openDatabase(
    path,
    version: 2,
    onCreate: (Database db, int version) async {
      await db.execute('''
        CREATE TABLE Orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_number TEXT NOT NULL,
          device_number TEXT NOT NULL,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
          phone_number TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE Devices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mac_address TEXT NOT NULL,    
          status INTEGER NOT NULL DEFAULT 1 -- 1 تعني true و 0 تعني false

        )
      ''');
    },
    onUpgrade: (Database db, int oldVersion, int newVersion) async {
      // Handle schema changes if needed
    },
  );
}

// Insert an order
Future<int> insertOrder(Database db, String orderNumber, String deviceNumber,
    String phoneNumber) async {
  try {
    return await db.insert(
      'Orders',
      {
        'order_number': orderNumber,
        'device_number': deviceNumber,
        'phone_number': phoneNumber
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    print('Error inserting order: $e');
    rethrow;
  }
}

// Query orders by phone number
Future<List<Map<String, dynamic>>> getOrdersByPhoneNumber(
    Database db, String phoneNumber) async {
  try {
    return await db.query(
      'Orders',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
  } catch (e) {
    print('Error querying orders by phone number: $e');
    rethrow;
  }
}

// Query orders by order number
Future<List<Map<String, dynamic>>> getOrdersByOrderNumber(
    Database db, String orderNumber) async {
  try {
    return await db.query(
      'Orders',
      where: 'order_number = ?',
      whereArgs: [orderNumber],
    );
  } catch (e) {
    print('Error querying orders by order number: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> getOrdersByDeviceNumber(
    Database db, String orderNumber) async {
  try {
    return await db.query(
      'Orders',
      where: 'device_number = ?',
      whereArgs: [orderNumber],
    );
  } catch (e) {
    print('Error querying orders by order number: $e');
    rethrow;
  }
}

// Query an order by ID
Future<Map<String, dynamic>?> getOrderById(Database db, int id) async {
  try {
    final List<Map<String, dynamic>> results = await db.query(
      'Orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  } catch (e) {
    print('Error querying order by id: $e');
    rethrow;
  }
}

// Delete an order by order number
Future<void> deleteOrderByOrderNumber(Database db, String orderNumber) async {
  try {
    await db.delete(
      'Orders',
      where: 'order_number = ?',
      whereArgs: [orderNumber],
    );
  } catch (e) {
    print('Error deleting order by order number: $e');
    rethrow;
  }
}

// Insert a device
Future<int> insertDevice(Database db, String macAddress, int id) async {
  try {
    return await db.insert(
      'Devices',
      {'id': id, 'mac_address': macAddress, 'status': "available"},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    print('Error inserting device: $e');
    rethrow;
  }
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

// Query all devices
Future<List<Map<String, dynamic>>> getDevices(Database db) async {
  try {
    return await db.query('Devices');
  } catch (e) {
    print('Error querying devices: $e');
    rethrow;
  }
}

// Query a device by ID
Future<Map<String, dynamic>?> getDeviceById(Database db, int id) async {
  try {
    final List<Map<String, dynamic>> results = await db.query(
      'Devices',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  } catch (e) {
    print('Error querying device by id: $e');
    rethrow;
  }
}

// Delete a device by MAC address
Future<void> deleteDeviceByMacAddress(Database db, String macAddress) async {
  try {
    await db.delete(
      'Devices',
      where: 'mac_address = ?',
      whereArgs: [macAddress],
    );
  } catch (e) {
    print('Error deleting device by MAC address: $e');
    rethrow;
  }
}

// Delete a device by ID
Future<void> deleteDeviceById(Database db, int id) async {
  try {
    await db.delete(
      'Devices',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Device with ID $id deleted successfully.');
  } catch (e) {
    print('Error deleting device by ID: $e');
    rethrow;
  }
}

// Fetch the latest device ID
Future<int> getLatestDeviceId(Database db) async {
  try {
    final List<Map<String, dynamic>> result = await db.query(
      'Devices',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      return 0; // No devices in the table
    }
  } catch (e) {
    print('Error fetching latest device ID: $e');
    rethrow;
  }
}

// Update the order number for an existing order
Future<void> updateOrderNumber(
    Database db, String oldOrderNumber, String newOrderNumber) async {
  try {
    // Update the order number where the old order number matches
    int count = await db.update(
      'Orders',
      {
        'order_number': newOrderNumber, // Set the new order number
      },
      where: 'order_number = ?', // Find the row with the old order number
      whereArgs: [
        oldOrderNumber
      ], // Provide the old order number as the argument
    );

    if (count > 0) {
      print(
          "Order number updated successfully from $oldOrderNumber to $newOrderNumber.");
    } else {
      print("No order found with the order number: $oldOrderNumber.");
    }
  } catch (e) {
    print('Error updating order number: $e');
    rethrow;
  }
}

// Add a new device with an incremented ID
Future<int> addNewDevice(Database db, String macAddress) async {
  try {
    int latestId = await getLatestDeviceId(db);
    int newId = latestId + 1;

    await insertDevice(db, macAddress, newId);
    print('Device added with ID: $newId');
    return newId; // Return the new device ID
  } catch (e) {
    print('Error adding new device: $e');
    rethrow;
  }
}
