import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShareUrlScreen extends StatefulWidget {
  final String? sharedUrl;
  const ShareUrlScreen({Key? key, required this.sharedUrl}) : super(key: key);
  @override
  _ShareUrlScreenState createState() => _ShareUrlScreenState();
}

class _ShareUrlScreenState extends State<ShareUrlScreen> {
  String? sharedUrl; // Variable to store the shared URL


  @override
  void initState() {
    super.initState();
    // Logic to check for URL passed (e.g., from deep linking)
     print("here in sharing");
    //_handleSharedUrl();
  }

  // Method to process shared URL
  Future<void> _handleSharedUrl() async {
    final Uri? url = Uri.tryParse(sharedUrl ?? '');  // Parse URL if it's available
    if (url != null) {
      // Fetch article content from backend using the shared URL
      final response = await http.get(Uri.parse("https://backendapi.com/article?url=$url"));
      if (response.statusCode == 200) {
        // Process the response (e.g., show quiz options)
        print('Fetched data: ${response.body}');
      } else {
        // Handle error
        print('Failed to load article');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Share URL with EasyQz')),
      body: sharedUrl == null
          ? Center(child: CircularProgressIndicator())  // Show loading if no URL
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Shared URL: $sharedUrl'),
          ElevatedButton(
            onPressed: () {
              // Handle the quiz data fetching and display
            },
            child: Text('Start Quiz'),
          ),
        ],
      ),
    );
  }
}
