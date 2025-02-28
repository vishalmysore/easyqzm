import 'package:easyqzm/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../model/performanceupdate.dart';
import '../model/user.dart';
import '../model/userperformance.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;

  const UserProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserPerformance? userPerformance;
  List<String> notifications = [];
  List<String> challenges = [];


  @override
  void initState() {
    super.initState();
    _fetchUserPerformance();
    _setupWebSocket();
  }

  // Fetch User Performance from REST API
  Future<void> _fetchUserPerformance() async {
    UserPerformance? perfo = await ApiService().fetchUserPerformance();
    setState(() {  // ✅ Ensure Flutter updates the UI
      userPerformance = perfo;
    });
  }

  // Setup WebSocket connection for Notifications & Challenges
  void _setupWebSocket() {

  }

  @override
  void dispose() {

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.user.name}'s Profile")),
      body: userPerformance == null
          ? Center(child: CircularProgressIndicator()) // Show spinner until data is loaded
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserSection(),
            _buildNotificationsSection(),
            _buildChallengesSection(),
          ],
        ),
      ),
    );
  }

  // Section 1: User Information & Performance
  Widget _buildUserSection() {
    return Card(
      margin: EdgeInsets.all(10),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage(widget.user.avatar)),
        title: Text(widget.user.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Quiz Type: ${userPerformance?.quizType ?? ''}"),
      ),
    );
  }

  // Section 2: Notifications
  Widget _buildNotificationsSection() {
    return Consumer<PerformanceUpdate>(
      builder: (context, performanceUpdate, child) {
        return Card(
          margin: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  "Notifications",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              if (performanceUpdate.notifications.isEmpty)
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text("No new notifications", style: TextStyle(fontSize: 16)),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blue.shade100),
                    columns: [
                      DataColumn(label: Text("User", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Topic", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Quiz Type", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: performanceUpdate.notifications.map((notif) {
                      return DataRow(cells: [
                        DataCell(Text(notif["userId"])),  // User
                        DataCell(Text(notif["topics"])),  // Topic
                        DataCell(
                          notif["quizType"] == "LINK"
                              ? InkWell(
                            child: Text(
                              notif["linkUrl"],
                              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                            onTap: () => launchUrl(Uri.parse(notif["linkUrl"])),
                          )
                              : Text(notif["quizType"]),
                        ),
                        DataCell(
                          ElevatedButton(
                            onPressed: () => _challengeUser(notif["userId"]),
                            child: Text("Challenge"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

// Mock function for challenge action
  void _challengeUser(String userId) {
    print("Challenge sent to $userId!");
  }

  // Section 3: Challenges
  Widget _buildChallengesSection() {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          ListTile(title: Text("Challenges", style: TextStyle(fontWeight: FontWeight.bold))),
          ...challenges.map((challenge) => ListTile(title: Text(challenge))).toList(),
        ],
      ),
    );
  }
}
