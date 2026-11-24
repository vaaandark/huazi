class Work {
  final String id;
  final String title;
  final String? author;
  final String? dynasty;
  final String? script;
  final String? carrier;
  final String? holder;
  final String? rubbing;
  final String? layout;
  final String? summary;
  final String? description;
  final String? transcription;
  final String? rights;
  final int? lines;
  final int? charsPerLine;
  final int imageCount;

  const Work({
    required this.id,
    required this.title,
    this.author,
    this.dynasty,
    this.script,
    this.carrier,
    this.holder,
    this.rubbing,
    this.layout,
    this.summary,
    this.description,
    this.transcription,
    this.rights,
    this.lines,
    this.charsPerLine,
    this.imageCount = 0,
  });

  factory Work.fromRow(Map<String, Object?> r) => Work(
        id: r['id'] as String,
        title: r['title'] as String,
        author: r['author'] as String?,
        dynasty: r['dynasty'] as String?,
        script: r['script'] as String?,
        carrier: r['carrier'] as String?,
        holder: r['holder'] as String?,
        rubbing: r['rubbing'] as String?,
        layout: r['layout'] as String?,
        summary: r['summary'] as String?,
        description: r['description'] as String?,
        transcription: r['transcription'] as String?,
        rights: r['rights'] as String?,
        lines: r['lines'] as int?,
        charsPerLine: r['chars_per_line'] as int?,
        imageCount: (r['image_count'] as int?) ?? 0,
      );

  String get byline =>
      [author, dynasty].where((e) => e != null && e.isNotEmpty).join(' · ');
}

class WorkImage {
  final int seq;
  final String? thumb;
  final String? remote;
  final String? license;

  const WorkImage({required this.seq, this.thumb, this.remote, this.license});

  factory WorkImage.fromRow(Map<String, Object?> r) => WorkImage(
        seq: r['seq'] as int,
        thumb: r['thumb'] as String?,
        remote: r['remote'] as String?,
        license: r['license'] as String?,
      );

  String? get assetPath {
    if (thumb == null) return null;
    final name = thumb!.split('/').last;
    return 'assets/thumbs/$name';
  }
}

class Person {
  final String id;
  final String name;
  final String? dynasty;
  final int workCount;

  const Person({
    required this.id,
    required this.name,
    this.dynasty,
    this.workCount = 0,
  });

  factory Person.fromRow(Map<String, Object?> r) => Person(
        id: r['id'] as String,
        name: r['name'] as String,
        dynasty: r['dynasty'] as String?,
        workCount: (r['work_count'] as int?) ?? 0,
      );
}

class WorkFilter {
  final String? script;
  final String? dynasty;
  final String? carrier;
  final String query;

  const WorkFilter({this.script, this.dynasty, this.carrier, this.query = ''});

  bool get isEmpty =>
      script == null && dynasty == null && carrier == null && query.isEmpty;

  WorkFilter copyWith({
    String? script,
    String? dynasty,
    String? carrier,
    String? query,
    bool clearScript = false,
    bool clearDynasty = false,
    bool clearCarrier = false,
  }) =>
      WorkFilter(
        script: clearScript ? null : (script ?? this.script),
        dynasty: clearDynasty ? null : (dynasty ?? this.dynasty),
        carrier: clearCarrier ? null : (carrier ?? this.carrier),
        query: query ?? this.query,
      );
}

const scriptLabels = {
  'kai': '楷书',
  'xing': '行书',
  'cao': '草书',
  'li': '隶书',
  'zhuan': '篆书',
};

const carrierLabels = {
  'beike': '碑刻',
  'muzhi': '墓志',
  'moya': '摩崖',
  'zaoxiang': '造像',
  'ketie': '刻帖',
  'moji': '墨迹',
  'xiejing': '写经',
};
