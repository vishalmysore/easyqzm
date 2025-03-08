import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../model/story.dart';
import '../search_screen.dart';
import '../service/api_service.dart';

class StoryScreen extends StatefulWidget {
  final String type; // Accepts 'story', 'math', 'science'

  const StoryScreen({Key? key, required this.type}) : super(key: key);
  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  Story? story;
  bool isLoading = true;
  int remainingTime = 300; // Example: 10 seconds for testing, adjust as needed
  Timer? _timer;
  bool isTimeUp = false; // To track if time is up and show the button

  @override
  void initState() {
    super.initState();
    fetchStory();
  }

  Future<void> fetchStory() async {
    Story? fetchedStory = await ApiService().fetchStory(widget.type);
    if (mounted) {
      setState(() {
        story = fetchedStory;
        isLoading = false;
        startCountdown(fetchedStory);
      });
    }
  }

  void startCountdown(Story? fetchedStory) {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (remainingTime > 0) {
            remainingTime--;
          } else {
            _timer?.cancel();
            isTimeUp = true; // Time is up, show the "Take Test" button
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void navigateToSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          text: null, // Pass whatever data you need
          story: story,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(story?.title ?? "Loading..."),
      content: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            child: Text(story?.storyText ?? "No story available"),
          ),
          SizedBox(height: 20),
          if (!isTimeUp)
            Text(
              "Closing in: ${remainingTime ~/ 60}:${(remainingTime % 60)
                  .toString()
                  .padLeft(2, '0')}",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          if (isTimeUp)
            Stack(
              children: [
                // Apply blur effect only if time is up
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  // Adjust blur level as needed
                  child: Container(
                    color: Colors.black.withOpacity(
                        0), // Make the container invisible while keeping the blur effect
                  ),
                ),
                // Show blurred text when time is up
                Text(
                  "Time is up! Take Test",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black.withOpacity(
                        0.5), // Make the text slightly transparent for better visibility
                  ),
                ),
              ],
            ),
          // Always display "Take Test" button
          ElevatedButton(
            onPressed: navigateToSearchScreen,
            child: Text("Take Test"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
          child: Text("Close"),
        ),
      ],
    );
  }
}
