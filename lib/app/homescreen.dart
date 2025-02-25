import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home_screen.dart';
import '../model/sharedtext.dart';
import '../search_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Add your notification functionality here
              print("Notifications tapped");
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
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://easyqz.online/easylogo2.png'),
            ),
            label: 'Profile',
          ),
        ],
        onTap: (int index) {
          // Navigate to Home screen on tap
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
            print("Profile tapped");
          }
        },
      ),
    );
  }
}