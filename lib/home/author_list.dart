import 'package:flutter/material.dart';

class TopAuthorsPage extends StatelessWidget {
  final List<Author> authors = [
    Author(
      name: "John Doe",
      topics: ["AI", "Flutter", "Cybersecurity"],
      highestScore: 98,
      bio: "Tech enthusiast, AI researcher, and Flutter expert.",
      imageUrl: "https://i.pravatar.cc/150?img=14", // Replace with actual image
    ),
    Author(
      name: "Jane Smith",
      topics: ["Data Science", "Quantum Computing"],
      highestScore: 95,
      bio: "Passionate about data and the future of computing.",
      imageUrl: "https://i.pravatar.cc/150?img=18",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Top Authors"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: authors.length,
        itemBuilder: (context, index) {
          return _buildAuthorCard(authors[index]);
        },
      ),
    );
  }

  Widget _buildAuthorCard(Author author) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Image
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                "https://api.allorigins.win/raw?url=${author.imageUrl}",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            // Author Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        author.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      _buildScoreBadge(author.highestScore),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Topics Covered
                  Wrap(
                    spacing: 8,
                    children: author.topics
                        .map((topic) => Chip(
                      label: Text(topic),
                      backgroundColor: Colors.deepPurple[100],
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 8),
                  // Short Bio
                  Text(
                    author.bio,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Score: $score",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Author Model
class Author {
  final String name;
  final List<String> topics;
  final int highestScore;
  final String bio;
  final String imageUrl;

  Author({
    required this.name,
    required this.topics,
    required this.highestScore,
    required this.bio,
    required this.imageUrl,
  });
}
