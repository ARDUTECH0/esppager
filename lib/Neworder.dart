import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pager/addNewDevice.dart';
import 'package:pager/img.dart';
import 'package:pager/initDatabase.dart';
import 'package:pager/main.dart';
import 'package:sqflite/sqflite.dart';

class DottedBorder extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final Color borderColor;

  const DottedBorder({
    required this.child,
    this.borderWidth = 1.0,
    this.borderColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedBorderPainter(
        borderWidth: borderWidth,
        borderColor: borderColor,
      ),
      child: child,
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final double borderWidth;
  final Color borderColor;

  DottedBorderPainter({
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final double dotSpacing = 2.0; // Spacing between dots
    final double dotSize = 4.0; // Size of each dot

    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final double dashWidth = dotSize + dotSpacing;

    canvas.drawPath(
      dashPath(path, dashWidth, dotSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  Path dashPath(Path path, double dashWidth, double dashSize) {
    final Path dashedPath = Path();
    final PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double length = 0;
      while (length < pathMetric.length) {
        final double nextLength = length + dashSize;
        final Path extractPath = pathMetric.extractPath(length, nextLength);
        dashedPath.addPath(extractPath, Offset.zero);
        length += dashWidth;
      }
    }
    return dashedPath;
  }
}

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({
    Key? key,
  }) : super(key: key);

  @override
  _DeviceManagementScreenState createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  List<DeviceStatus> devices = [];
  late Database _db;
  Timer? _timer; // Add a Timer variable
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    // Cancel timers, listeners, or other operations here
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeDatabase();

    // Initialize a Timer to call _loadDevices every 2 seconds
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _loadDevices();
    });
  }

  Future<void> _initializeDatabase() async {
    _db = await initDatabase();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    List<Map<String, dynamic>> deviceRows = await getDevices(_db);

    if (_isDisposed) return;

    setState(() {
      devices = deviceRows.map((row) {
        return DeviceStatus.available;
      }).toList();
    });
  }

  void _addNewDevice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddDeviceScreen()),
    );
  }

  void _onDeleteDevice(int deviceNumber) async {
    try {
      // Assuming you have a function `deleteDevice` in your database code
      await deleteDeviceById(_db, deviceNumber); // Delete device from database
      setState(() {
        devices.removeAt(deviceNumber - 1); // Remove device from UI list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device $deviceNumber deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNewRequestForm(
      {String orderNumber = '',
      String phoneNumber = '',
      String deviceNumber = ''}) {
    showModalBottomSheet(
      isScrollControlled: true, // This allows the bottom sheet to be scrollable
      context: context,
      builder: (context) => DeviceDetailsPanel(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        orderNumber: orderNumber,
        phoneNumber: phoneNumber,
        deviceNumber: deviceNumber,
        isEditing: orderNumber.isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe0e0e0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFe0e0e0),
        title: Text('Device Management'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;

          return width > 600
              ? _buildTabletLayout(width, height)
              : _buildMobileLayout();
        },
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          // Use SizedBox.shrink() to represent no FloatingActionButton on tablets
          return width > 600
              ? SizedBox.shrink() // Equivalent to "no widget" for tablets
              : FloatingActionButton(
                  onPressed: () => _showNewRequestForm(),
                  child: Icon(Icons.add),
                  tooltip: 'Add New Request',
                );
        },
      ),
    );
  }

  void _onDeviceTap(int deviceNumber) async {
    webSocketService.sendMessage("SEND $deviceNumber cheak");
  }

  Widget _buildTabletLayout(double width, double height) {
    double panelWidth = width * 0.30;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AddNewDeviceButton(onPressed: _addNewDevice),
                SizedBox(width: 20),

                Container(
                  width: 500,
                  height: 500,
                  child: DottedBorder(
                    borderWidth: 2,
                    borderColor: Colors.black,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10.0,
                        crossAxisSpacing: 10.0,
                      ),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        return DeviceTile(
                          deviceNumber: index + 1,
                          status: devices[index],
                          onTap: _onDeviceTap,
                          onDelete: _onDeleteDevice,
                        );
                      },
                    ),
                  ),
                ),
                // SingleChildScrollView(
                //   child: DeviceDetailsPanel(
                //     width: panelWidth,
                //     height: 150,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(height: 20),
          AddNewDeviceButton(onPressed: _addNewDevice),
          SizedBox(height: 20),
          Expanded(
            child: DottedBorder(
              borderWidth: 2,
              borderColor: Colors.black,
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                ),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  return DeviceTile(
                    deviceNumber: index + 1,
                    status: devices[index],
                    onTap: _onDeviceTap,
                    onDelete: _onDeleteDevice,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DeviceStatus { available, unavailable }

class DeviceTile extends StatelessWidget {
  final int deviceNumber;
  final DeviceStatus status;
  final Function(int) onTap;
  final Function(int) onDelete; // New callback for delete action

  const DeviceTile({
    required this.deviceNumber,
    required this.status,
    required this.onTap,
    required this.onDelete, // Pass delete function
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(deviceNumber), // Single tap prints device number
      onLongPress: () => _showDeleteDialog(
          context, deviceNumber), // Long press shows delete option
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(IconManager.Ts), // Update with actual image path
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$deviceNumber',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show a dialog with delete option when long-pressed
  void _showDeleteDialog(BuildContext context, int deviceNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Device'),
          content:
              Text('Are you sure you want to delete device $deviceNumber?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                onDelete(deviceNumber); // Trigger delete callback
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}

class AddNewDeviceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddNewDeviceButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(IconManager.Ts), // Update with actual image path
            fit: BoxFit.cover,
          ),
        ),
        child: const Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 50,
                    color: Colors.black,
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'إضافة جهاز جديد',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceDetailsPanel extends StatefulWidget {
  final double width;
  final double height;
  final String orderNumber;
  final String phoneNumber;
  final String deviceNumber;
  final bool isEditing;

  DeviceDetailsPanel({
    required this.width,
    required this.height,
    this.orderNumber = '',
    this.phoneNumber = '',
    this.deviceNumber = '',
    this.isEditing = false,
  });

  @override
  State<DeviceDetailsPanel> createState() => _DeviceDetailsPanelState();
}

class _DeviceDetailsPanelState extends State<DeviceDetailsPanel> {
  late Database _db;

  final TextEditingController _orderNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _deviceNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();

    // Initialize fields if editing
    if (widget.isEditing) {
      _orderNumberController.text = widget.orderNumber;
      _phoneNumberController.text = widget.phoneNumber;
      _deviceNumberController.text = widget.deviceNumber;
    }
  }

  Future<void> _initializeDatabase() async {
    _db = await initDatabase();
  }

  Future<void> _saveChanges() async {
    // try {
    //   if (widget.isEditing) {
    //     await updateOrder(
    //       _db,
    //       _orderNumberController.text,
    //     );
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Order updated successfully!'),
    //         backgroundColor: Colors.green,
    //       ),
    //     );
    //   } else {
    //     await insertOrder(
    //       _db,
    //       _orderNumberController.text,
    //       _deviceNumberController.text,
    //       _phoneNumberController.text,
    //     );
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Order added successfully!'),
    //         backgroundColor: Colors.green,
    //       ),
    //     );
    //   }
    //   // Clear fields after successful operation
    //   _orderNumberController.clear();
    //   _deviceNumberController.clear();
    //   _phoneNumberController.clear();
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Failed to save order: $e'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _phoneNumberController.dispose();
    _deviceNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current date and time
    final now = DateTime.now();
    final dayFormatter = DateFormat('EEEE'); // Day in English
    final dateFormatter = DateFormat('yyyy/MM/dd');
    final timeFormatter = DateFormat('HH:mm');

    final dayInEnglish = dayFormatter.format(now);
    final date = dateFormatter.format(now);
    final time = timeFormatter.format(now);

    final dayInArabic = mapDayToArabic(dayInEnglish); // Convert to Arabic

    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(60)),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            width: widget.width,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomRight: Radius.circular(15)),
            ),
            child: Center(
              child: Text(
                widget.isEditing ? 'تعديل طلب' : 'طلب جديد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: widget.height * 0.02),
          Text(
            '$dayInArabic\n$date\n$time',
            style: TextStyle(
              fontSize: 30,
              fontFamily: "re",
              fontWeight: FontWeight.w900,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: widget.height * 0.02),
          _buildTextField('رقم الفاتورة', _orderNumberController),
          SizedBox(height: widget.height * 0.01),
          _buildTextField('رقم الجهاز', _deviceNumberController),
          SizedBox(height: widget.height * 0.01),
          _buildTextField('رقم الهاتف', _phoneNumberController),
          SizedBox(height: widget.height * 0.03),
          GestureDetector(
            onTap: _saveChanges,
            child: Container(
              height: 50,
              width: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  widget.isEditing ? 'تعديل' : 'إرسال',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Container(
          height: 50,
          width: 200,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Colors.white],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Mapping function to convert English day names to Arabic
  String mapDayToArabic(String day) {
    final dayMap = {
      'Monday': 'الاثنين',
      'Tuesday': 'الثلاثاء',
      'Wednesday': 'الأربعاء',
      'Thursday': 'الخميس',
      'Friday': 'الجمعة',
      'Saturday': 'السبت',
      'Sunday': 'الأحد',
    };

    return dayMap[day] ?? day; // Default to English if not found
  }
}
