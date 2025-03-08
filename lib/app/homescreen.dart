import 'dart:async';
import 'package:easyqzm/app/news.dart';
import 'package:easyqzm/app/sotryscreen.dart';
import 'package:easyqzm/app/storytypes.dart';

import '../util/debug.dart' as debug;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';

import '../home_screen.dart';
import '../model/sharedtext.dart';
import '../model/user.dart';
import '../model/userupdate.dart';
import '../profile/userprofile.dart';
import '../search_screen.dart';
import '../service/websocket.dart';
import 'help.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late WebSocketService _wsService;
  late Stream scoreStream;
  
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      _counter++;
    });


  }

  void _help () {
    debug.d('clicked');
  }




  @override
  Widget build(BuildContext context) {



    return    LoaderOverlay (child: Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 10), // Adjust the font size as needed
        ),
        actions: <Widget>[
          Consumer<UserUpdate>(
            builder: (context, userUpdate, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.bell),
                    onPressed: () {
                    //  debug.d("Notifications tapped");
                      // You can reset count or show notifications here
                      userUpdate.clearNotifications();
                    },
                  ),
                  if (userUpdate.notificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${userUpdate.notificationCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Adds space from top
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Keeps elements at the top
          crossAxisAlignment: CrossAxisAlignment.center, // Centers elements horizontally
          children: <Widget>[
            // Bandwidth warning message
            Container(
              width: double.infinity, // Ensures the container spans full width for centering text
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmallScreen = constraints.maxWidth < 350;
                  return Text(
                    isSmallScreen
                        ? "⚠️ EasyQz is in pre-Beta with limited bandwidth.\nIt may be slow at times. 🐻 Please bear with us! ⚠️"
                        : "⚠️ EasyQz is currently in pre-Beta and running on limited bandwidth and may be slow at times. 🐻 Please bear with us! ⚠️",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),

            // Instruction text
            LayoutBuilder(
              builder: (context, constraints) {
                bool isSmallScreen = constraints.maxWidth < 350;
                return Text(
                  isSmallScreen
                      ? "Hit Search to start Quiz.\nOr click 'Read a story' or 'News':"
                      : "Hit the Search Button to start Quiz or Click on 'Read a story' or 'News':",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                );
              },
            ),

            const SizedBox(height: 10),

            // Shared Text Display
            Consumer<SharedTextModel>(
              builder: (context, sharedTextModel, child) {
                return Text(
                  sharedTextModel.sharedText.isEmpty
                      ? "No topic selected"
                      : sharedTextModel.sharedText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),



      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "StoryScreen",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StoryScreen(type:"stories"),
              );
            },
            tooltip: 'Tell me a Story',
            child: Icon(CupertinoIcons.book),
          ),
          SizedBox(height: 16), // Spacing between buttons

          FloatingActionButton(
            heroTag: "NewsScreen",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => NewsScreen(),
              );
            },
            tooltip: 'Current News',
            child: Icon(CupertinoIcons.news),
          ),
          SizedBox(height: 16), // Spacing between buttons
          FloatingActionMenu(), // Using the custom FAB menu
          SizedBox(height: 16), // Spacing between buttons
          FloatingActionButton(
            heroTag: "HelpScreen",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => HelpScreen(),
              );
            },
            tooltip: 'Help and Support',
            child: Icon(Icons.chat_bubble),
          ),
          SizedBox(height: 16), // Spacing between buttons

        ],
      ),

        bottomNavigationBar: Consumer<UserUpdate>(

          builder: (context, userUpdate, child) {
            final User? currentUser = userUpdate.user;
            if (userUpdate.user == null) {
              context.loaderOverlay.show(); // Show spinner
            } else {

              context.loaderOverlay.hide(); // Hide spinner once loaded
            }
            return BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: userUpdate.user != null
                      ? CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(
            userUpdate.user?.avatar?.isNotEmpty == true
            ? "https://api.allorigins.win/raw?url=${userUpdate.user!.avatar}"
                : "https://api.allorigins.win/raw?url=https://i.pravatar.cc/150?img=14", // Fallback if no avatar
            ),
            )
                      : const Icon(Icons.person), // Default icon
                  label: userUpdate.user?.name ?? 'Profile', // Moved inside Consumer
                ),
              ],
              onTap: (int index) {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } else if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchScreen(text: null)),
                  );
                } else if (index == 2) {
                  if(currentUser != null) {
                    debug.d("Profile tapped for $currentUser");
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserProfileScreen(user: currentUser)),
                    );
                  }

                }
              },
            );

          },
        ),
    )
    );
  }
}