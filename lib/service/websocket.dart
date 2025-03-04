import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:universal_html/html.dart';
import '../util/debug.dart' as debug;
class WebSocketService {
  final Map<String, WebSocketChannel> _channels = {}; // Store WebSocket connections by endpoint
  final Map<String, StreamController> _messageControllers = {}; // Store StreamControllers for each connection

  // Connect to a WebSocket endpoint
  Stream<dynamic> connect(String endpoint,String token) {

    //final String? token = window.localStorage['jwtToken'];
    final String wsUrl = kReleaseMode
        ? 'wss://vishalmysore-easyqserver.hf.space/ws/'  // Production WebSocket URL
        : 'ws://localhost:7860/ws/';  // Local WebSocket URL

    if (_channels.containsKey(endpoint)) {
      debug.d('Already connected to $endpoint');
      return _messageControllers[endpoint]!.stream;
    }

    final url = '$wsUrl$endpoint?token=$token';
    final socket = WebSocketChannel.connect(Uri.parse(url));
    _channels[endpoint] = socket;
    _messageControllers[endpoint] = StreamController<dynamic>();

    socket.stream.listen(
          (message) {
        debug.d('Message received from $endpoint: $message');
        _messageControllers[endpoint]!.sink.add(message); // Emit the received message
      },
      onError: (error) {
        debug.d('WebSocket error for $endpoint: $error');
        _messageControllers[endpoint]!.sink.addError(error); // Emit error
      },
      onDone: () {
        debug.d('WebSocket connection closed for $endpoint');
        _messageControllers[endpoint]!.close(); // Close the stream controller
        _channels.remove(endpoint);
        _messageControllers.remove(endpoint);
      },
    );

    return _messageControllers[endpoint]!.stream;
  }

  // Send a message to the WebSocket
  void sendMessage(String endpoint, String message) {
    final socket = _channels[endpoint];
    if (socket != null && socket.closeCode == null) { // If connected and the socket is open
      socket.sink.add(message);
      debug.d('Message sent to $endpoint: $message');
    } else {
      debug.d('WebSocket not connected to $endpoint');
    }
  }

  // Close WebSocket connection
  void closeConnection(String endpoint) {
    final socket = _channels[endpoint];
    if (socket != null) {
      socket.sink.close();
      _channels.remove(endpoint);
      _messageControllers[endpoint]?.close();
      _messageControllers.remove(endpoint);
      debug.d('WebSocket connection closed for $endpoint');
    }
  }
}
