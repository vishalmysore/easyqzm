import 'package:flutter/material.dart';
import 'package:word_cloud/word_cloud_data.dart';
import 'package:word_cloud/word_cloud_shape.dart';
import 'package:word_cloud/word_cloud_tap.dart';
import 'package:word_cloud/word_cloud_tap_view.dart';
import 'package:word_cloud/word_cloud_view.dart';

class WordCloudPage extends StatefulWidget {
  const WordCloudPage({super.key, required this.title});

  final String title;

  @override
  State<WordCloudPage> createState() => WordCloudScreen();
}

class WordCloudScreen extends State<WordCloudPage> {
  List<Map> wordList = [
    {'word': 'Apple', 'value': 100},
    {'word': 'Samsung', 'value': 60},
    {'word': 'Intel', 'value': 55},
    {'word': 'Tesla', 'value': 50},
    {'word': 'AMD', 'value': 40},
    {'word': 'Google', 'value': 35},
    {'word': 'Java', 'value': 115},
    {'word': 'Spring', 'value': 55},
  ];

  Map<String, List<String>> topicWebsites = {
    'Apple': ['CNN', 'BBC', 'Forbes'],
    'Samsung': ['TechCrunch', 'CNET', 'Gizmodo'],
    'Intel': ['Wired', 'The Verge', 'Engadget'],
    'Tesla': ['Bloomberg', 'CNBC', 'Yahoo Finance'],
    'AMD': ['Toms Hardware', 'AnandTech', 'PC Gamer'],
    'Google': ['TechRadar', 'Android Authority', 'The Next Web'],
  };

  String selectedTopic = '';
  int selectedCount = 0;
  List<String> websites = [];

  @override
  Widget build(BuildContext context) {
    WordCloudData wcData = WordCloudData(data: wordList);
    WordCloudTap wordTaps = WordCloudTap();

    for (int i = 0; i < wordList.length; i++) {
      void tap() {
        setState(() {
          selectedTopic = wordList[i]['word'];
          selectedCount = wordList[i]['value'];
          websites = topicWebsites[selectedTopic] ?? [];
        });
      }
      wordTaps.addWordtap(wordList[i]['word'], tap);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Selected Topic: $selectedTopic', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Readers Count: $selectedCount', style: TextStyle(fontSize: 18)),
            if (websites.isNotEmpty)
              Column(
                children: websites.map((site) => Text('- $site', style: TextStyle(fontSize: 16))).toList(),
              ),
            SizedBox(height: 20),
            WordCloudTapView(
              data: wcData,
              wordtap: wordTaps,
              mapcolor: Colors.blueGrey.shade100,
              mapwidth: 500,
              mapheight: 500,
              fontWeight: FontWeight.bold,
              shape: WordCloudCircle(radius: 250),
              colorlist: [Colors.black, Colors.redAccent, Colors.indigoAccent],
            ),
          ],
        ),
      ),
    );
  }
}
