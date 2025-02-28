import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:universal_html/html.dart';
class WebSocketService {
  final Map<String, WebSocketChannel> _channels = {}; // Store WebSocket connections by endpoint
  final Map<String, StreamController> _messageControllers = {}; // Store StreamControllers for each connection

  // Connect to a WebSocket endpoint
  Stream<dynamic> connect(String endpoint) {

    final String? token = window.localStorage['jwtToken'];
    final wsUrl = const String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:7860/ws/',  // Default for local environment
    );

    if (_channels.containsKey(endpoint)) {
      print('Already connected to $endpoint');
      return _messageControllers[endpoint]!.stream;
    }

    final url = '$wsUrl$endpoint?token=$token';
    final socket = WebSocketChannel.connect(Uri.parse(url));
    _channels[endpoint] = socket;
    _messageControllers[endpoint] = StreamController<dynamic>();

    socket.stream.listen(
          (message) {
        print('Message received from $endpoint: $message');
        _messageControllers[endpoint]!.sink.add(message); // Emit the received message
      },
      onError: (error) {
        print('WebSocket error for $endpoint: $error');
        _messageControllers[endpoint]!.sink.addError(error); // Emit error
      },
      onDone: () {
        print('WebSocket connection closed for $endpoint');
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
      print('Message sent to $endpoint: $message');
    } else {
      print('WebSocket not connected to $endpoint');
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
      print('WebSocket connection closed for $endpoint');
    }
  }
}
