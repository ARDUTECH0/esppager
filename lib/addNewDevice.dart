import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pager/OrderS.dart';
import 'package:pager/bluetooth_service.dart';
import 'package:pager/img.dart';
import 'package:pager/initDatabase.dart';
import 'package:pager/main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  late Database _db;
  final TextEditingController _controller = TextEditingController();
  QRViewController? _controllerQR;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool _isLoading = false; // Add this variable to track loading state

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _db = await initDatabase();
  }

  Future<void> _addNewDevice() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      String macAddress = _controller.text;

      // Check if macAddress is empty
      if (macAddress.isEmpty) {
        print('Error: MAC address is empty. Device not added.');
        setState(() {
          _isLoading = false; // Stop loading
        });
        return; // Exit the function if MAC address is empty
      }

      int newId = await addNewDevice(_db, macAddress);
      print('ADD $newId $macAddress');
      webSocketService.sendMessage("ADD $newId $macAddress");

      // Wait for three seconds
      await Future.delayed(Duration(seconds: 3));

      // Navigate to the horror page
      Navigator.pop(
        context,
        MaterialPageRoute(
            builder: (context) => App(
                  database: _db,
                )),
      );
    } catch (e) {
      print('Error in _addNewDevice: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  void _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRViewExample(
          onQRViewCreated: (controller) {
            _controllerQR = controller;
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _controller.text = result; // Set QR code data to text field
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe0e0e0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFe0e0e0),
        title: const Text("Add Device"),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // Show loading indicator
            : LayoutBuilder(
                builder: (context, constraints) {
                  bool isTablet = constraints.maxWidth > 600;
                  return Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: DottedBorder(
                      borderWidth: 2,
                      borderColor: Colors.black,
                      child: Container(
                        width: isTablet ? 800 : constraints.maxWidth * 0.9,
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Setting",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: isTablet ? 40.0 : 24.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            if (isTablet)
                              IconButton(
                                onPressed: _openCamera,
                                icon: Icon(
                                  Icons.camera,
                                  size: 80,
                                  color: Colors.black,
                                ),
                              ),
                            if (!isTablet)
                              SizedBox(
                                width: 100,
                                child: IconButton(
                                  onPressed: _openCamera,
                                  icon: Icon(
                                    Icons.camera,
                                    size: 60,
                                  ),
                                ),
                              ),
                            SizedBox(height: 20),
                            Text(
                              "رقم الشريحه",
                              style: TextStyle(
                                fontSize: isTablet ? 20.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3497d3),
                              ),
                            ),
                            SizedBox(height: 10),
                            _buildTextField("Enter MAC Address"),
                            SizedBox(height: 20),
                            AddNewDeviceButton(onPressed: _addNewDevice),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(13.8)),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Container(
          height: 50,
          width: double.infinity, // Adjust width to fit the container
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextFormField(
              controller: _controller,
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                hintText: hint,
                hintStyle: TextStyle(
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
}

class AddNewDeviceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddNewDeviceButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 150,
        height: 150,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    final double dotSpacing = 2.0;
    final double dotSize = 4.0;

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

class QRViewExample extends StatelessWidget {
  final Function(QRViewController) onQRViewCreated;

  QRViewExample({required this.onQRViewCreated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: QRView(
        key: GlobalKey(),
        onQRViewCreated: (QRViewController controller) {
          onQRViewCreated(controller);
          controller.scannedDataStream.listen((scanData) {
            controller.dispose(); // Stop scanning
            Navigator.pop(
                context,
                scanData
                    .code); // Pass the scanned data back to the previous screen
          });
        },
        overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
      ),
    );
  }
}
