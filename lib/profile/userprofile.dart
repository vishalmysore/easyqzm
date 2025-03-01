import 'package:easyqzm/service/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../model/performanceupdate.dart';
import '../model/user.dart';
import '../model/userperformance.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['openid', 'email', 'profile'],
  clientId: kReleaseMode
      ? "992082477434-5durkouoia0lo1o7pk9lpmp08mbcnfru.apps.googleusercontent.com" // Production
      : "992082477434-nbjvh0ub7ge30uj928muanlfj067726f.apps.googleusercontent.com", // Local
);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: SizedBox(
              width: 50,
              height: 50,
              child: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                  widget.user.avatar.isNotEmpty
                      ? "https://api.allorigins.win/raw?url=${widget.user.avatar}"
                      : "https://api.allorigins.win/raw?url=https://i.pravatar.cc/150?img=14", // Fallback avatar
                ),
              ),
            ),
            title: Text(
              widget.user.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email: ${widget.user.emailId ?? 'Not available'}"),
                Text("Quiz Type: ${userPerformance?.quizType ?? ''}"),
              ],
            ),
          ),
          Divider(), // Separates sections visually

          // Expert Topics Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              "Expert Topics: ${widget.user.expertTopics.isNotEmpty ? widget.user.expertTopics.join(', ') : 'None'}",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Achievements Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              "Achievements: ${widget.user.achievements.isNotEmpty ? widget.user.achievements.join(', ') : 'None'}",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Articles Section (as bullet points)
          if (widget.user.articles.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                "Articles:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.user.articles
                    .map((article) => Text("• $article", style: TextStyle(fontSize: 14)))
                    .toList(),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                "No articles available.",
                style: TextStyle(color: Colors.grey),
              ),
            ),

          // Sign-in button for non-permanent users
          if (!widget.user.isPermanent)
            Padding(
              padding: const EdgeInsets.all(10),
              child: ElevatedButton.icon(
                onPressed: _signInWithGoogle, // Function to handle sign-in
                icon: Icon(Icons.login),
                label: Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final String? accessToken = googleAuth.accessToken;
        final String? idToken = googleAuth.idToken; // ID Token (useful for backend auth)

        print("Signed in as: ${googleUser.displayName}");
        print("Email: ${googleUser.email}");
        print("Profile Picture: ${googleUser.photoUrl}");
        print("Access Token: $accessToken");
        print("ID Token: $idToken");

        // Store the access token if needed for API calls
        // You might send the ID Token to your backend for verification

        setState(() {
          // widget.user.name = googleUser.displayName ?? "Unknown User";
          // widget.user.emailId = googleUser.email;
          // widget.user.avatar = googleUser.photoUrl ?? "";
        });
      }
    } catch (error) {
      print("Google Sign-In Error: $error");
    }
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
