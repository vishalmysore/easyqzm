import 'dart:async';

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
    print('clicked');
  }




  @override
  Widget build(BuildContext context) {



    return    LoaderOverlay (child: Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          Consumer<UserUpdate>(
            builder: (context, userUpdate, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      print("Notifications tapped");
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Hit the Search Button to start Quiz:'),
           // Text(
           //   '$_counter',
           //   style: Theme.of(context).textTheme.headlineMedium,
           // ),
            Consumer<SharedTextModel>(
              builder: (context, sharedTextModel, child) {
                return Text(
                  sharedTextModel.sharedText.isEmpty
                      ? "No shared text"
                      : sharedTextModel.sharedText,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => HelpScreen(),
          );
        },
        tooltip: 'Help',
        child: Icon(Icons.help),
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
                    print("Profile tapped for $currentUser");
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