class Link {
  String url;
  String author;
  int totalAccessCount;
  String keywords;

  // Constructor
  Link({
    required this.url,
    required this.author,
    required this.totalAccessCount,
    required this.keywords,
  });

  // Factory constructor for creating an instance from a JSON map
  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      url: json['url'],
      author: json['author'],
      totalAccessCount: json['totalAccessCount'],
      keywords: json['keywords'],
    );
  }

  // Convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'author': author,
      'totalAccessCount': totalAccessCount,
      'keywords': keywords,
    };
  }

  // Optional: Override toString() for debugging
  @override
  String toString() {
    return 'Link(url: $url, author: $author, totalAccessCount: $totalAccessCount, keywords: $keywords)';
  }
}
