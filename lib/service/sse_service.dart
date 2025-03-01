import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:universal_html/html.dart';

import '../model/performanceupdate.dart';
class SSEService {
  final String baseURL = kReleaseMode
      ? 'https://vishalmysore-easyqserver.hf.space/bs/'  // Production URL
      : 'http://localhost:7860/bs/';  // Local development URL


  // Fetch the token from localStorage

  final StreamController<String> _streamController = StreamController.broadcast();
  StreamSubscription<SSEModel>? _sseSubscription;
  late PerformanceUpdate performanceUpdate;


  // Start Listening to SSE Events
  void connect(PerformanceUpdate notifier) {
    final String? token = window.localStorage['jwtToken'];
    final url = '${baseURL}broadcast?token=$token';
    performanceUpdate =notifier;
    SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: url,
        header: {
          "Accept": "text/event-stream",
          "Cache-Control": "no-cache",
        }).listen(
            (event) {
          print('Id: ' + (event.id ?? ""));
          print('Event: ' + (event.event ?? ""));
          print('Data: ' + (event.data ?? ""));
          notifier.updated(event);
        });
  }

  // Reconnect on failure
  void reconnect() {
    Future.delayed(Duration(seconds: 5), () {
      print('Reconnecting to SSE...');
      connect(performanceUpdate);
    });
  }

  // Close connection
  void disconnect() {
    _sseSubscription?.cancel();
    _streamController.close();
    print('SSE Disconnected');
  }

  // Expose SSE stream to listen for events
  Stream<String> get eventsStream => _streamController.stream;
}
