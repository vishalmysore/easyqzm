import 'package:easyqzm/app/sotryscreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class FloatingActionMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      backgroundColor: Colors.blue,
      overlayOpacity: 0.4, // Semi-transparent background
      children: [
        SpeedDialChild(
          child: Icon(CupertinoIcons.plus),
          label: "Math",
          onTap: () => showDialog(
            context: context,
            builder: (context) => StoryScreen(type: "math"),
          ),
        ),
        SpeedDialChild(
          child: Icon(CupertinoIcons.lab_flask),
          label: "Science",
          onTap: () => showDialog(
            context: context,
            builder: (context) => StoryScreen(type: "science"),
          ),
        ),
        SpeedDialChild(
          child: Icon(CupertinoIcons.clock),
          label: "History",
          onTap: () => showDialog(
            context: context,
            builder: (context) => StoryScreen(type: "history"),
          ),
        ),
        SpeedDialChild(
          child: Icon(CupertinoIcons.sportscourt),
          label: "Indoor Sports",
          onTap: () => showDialog(
            context: context,
            builder: (context) => StoryScreen(type: "indoorSports"),
          ),
        ),
        SpeedDialChild(
          child: Icon(CupertinoIcons.tree),
          label: "Outdoor Sports",
          onTap: () => showDialog(
            context: context,
            builder: (context) => StoryScreen(type: "outdoorSports"),
          ),
        ),
        SpeedDialChild(
          child: Icon(CupertinoIcons.building_2_fill),
          label: "Civics",
          onTap: () => showDialog(
            context: context,
            builder: (context) => StoryScreen(type: "civics"),
          ),
        ),
        SpeedDialChild(
          child: Icon(CupertinoIcons.globe),
          label: "Geography",
          onTap: () => showDialog(
            context: context,
            builder: (context) => StoryScreen(type: "geography"),
          ),
        ),
      ],
    );
  }
}
