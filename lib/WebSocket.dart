import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus {
  disconnected,
  connected,
}

class WebSocketService {
  WebSocketChannel? _channel;
  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  final _messageController = StreamController<dynamic>.broadcast();
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  Stream<dynamic> get incomingMessages => _messageController.stream;
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  WebSocketService() {
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    _updateConnectionStatus(ConnectionStatus.disconnected);

    try {
      if (kIsWeb) {
        final wsUrl = Uri.parse('ws://192.168.1.6:80/ws');
        _channel = WebSocketChannel.connect(wsUrl);
      } else {
        _channel = IOWebSocketChannel.connect('ws://192.168.1.6:80/ws');
      }

      _channel!.stream.listen(
        (message) {
          print("Received message from WebSocket: $message");
          _updateConnectionStatus(ConnectionStatus.connected);
          _messageController.add(message);
        },
        onError: (error) {
          print("WebSocket error: $error");
          //  _handleConnectionError();
        },
        onDone: () {
          print("WebSocket connection closed.");
          _updateConnectionStatus(ConnectionStatus.disconnected);
        },
      );
    } catch (e) {
      print("WebSocket initialization error: $e");
      // _handleConnectionError();
    }
  }

  bool isConnected() {
    return _currentStatus == ConnectionStatus.connected;
  }

  Future<void> redial() async {
    _updateConnectionStatus(ConnectionStatus.disconnected);
    Future.delayed(Duration(seconds: 1), () {
      _updateConnectionStatus(ConnectionStatus.disconnected);
      print("Trying to reconnect...");
      _initializeWebSocket();
    });
  }

  void _updateConnectionStatus(ConnectionStatus status) {
    _currentStatus = status;
    _connectionStatusController.add(status);
  }

  void sendMessage(String message) {
    if (_channel != null && _channel!.sink != null) {
      _channel!.sink.add(message);
    }
  }

  void sendJsonData(Map<String, dynamic> jsonData) {
    final jsonString = jsonEncode(jsonData);
    if (_channel != null && _channel!.sink != null) {
      _channel!.sink.add(jsonString);
    }
  }

  void dispose() {
    _updateConnectionStatus(ConnectionStatus.disconnected);

    if (_channel != null && _channel!.sink != null) {
      _channel!.sink.close();
    }
    _messageController.close();
    _connectionStatusController.close();
  }

  void someMethod() {}
}
