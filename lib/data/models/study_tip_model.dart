class StudyTipModel {
  final String id;
  final String title;
  final String category;
  final String summary;
  final String content;
  final bool isFavorite;

  StudyTipModel({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
    this.isFavorite = false,
  });

  StudyTipModel copyWith({
    String? id,
    String? title,
    String? category,
    String? summary,
    String? content,
    bool? isFavorite,
  }) {
    return StudyTipModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'summary': summary,
      'content': content,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory StudyTipModel.fromMap(Map<String, dynamic> map) {
    return StudyTipModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: (map['category'] as String?) ?? 'Study Habits',
      summary: (map['summary'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      isFavorite: map['isFavorite'] == 1 || map['isFavorite'] == true,
    );
  }
}
