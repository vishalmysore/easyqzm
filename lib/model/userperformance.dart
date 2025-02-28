class UserPerformance {
  final double overallScore;
  final String? quizType; // ✅ Make quizType nullable
  final List<dynamic> articles;
  final String topLink;
  final int overallWrongAnswers;
  final Map<String, String> strongAreas;
  final Map<String, String> weakAreas;

  UserPerformance({
    required this.overallScore,
    this.quizType, // ✅ Nullable now
    required this.articles,
    required this.topLink,
    required this.overallWrongAnswers,
    required this.strongAreas,
    required this.weakAreas,
  });

  // Factory constructor to create an instance from a JSON object
  factory UserPerformance.fromJson(Map<String, dynamic> json) {
    return UserPerformance(
      overallScore: (json['overallScore'] as num).toDouble(),
      quizType: json['quizType'] as String?, // ✅ Allow null
      articles: json['articles'] ?? [],
      topLink: json['topLink'] ?? 'No top link',
      overallWrongAnswers: json['overallWrongAnswers'] ?? 0,
      strongAreas: Map<String, String>.from(json['strongAreas'] ?? {}),
      weakAreas: Map<String, String>.from(json['weakAreas'] ?? {}),
    );
  }

  // Convert the model to JSON format
  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'quizType': quizType, // ✅ Will be null if not provided
      'articles': articles,
      'topLink': topLink,
      'overallWrongAnswers': overallWrongAnswers,
      'strongAreas': strongAreas,
      'weakAreas': weakAreas,
    };
  }
}
