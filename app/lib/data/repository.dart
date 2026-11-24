import 'database.dart';
import 'models.dart';

class Repository {
  Repository(this._db);
  final AppDatabase _db;

  static Repository? _instance;
  static Repository get instance => _instance!;

  static Future<Repository> init() async {
    if (_instance != null) return _instance!;
    final db = await AppDatabase.open();
    _instance = Repository(db);
    return _instance!;
  }

  List<Work> works({WorkFilter filter = const WorkFilter(), int limit = 500}) {
    final where = <String>['excluded = 0'];
    final args = <Object?>[];
    if (filter.script != null) {
      where.add('script = ?');
      args.add(filter.script);
    }
    if (filter.dynasty != null) {
      where.add('dynasty = ?');
      args.add(filter.dynasty);
    }
    if (filter.carrier != null) {
      where.add('carrier = ?');
      args.add(filter.carrier);
    }
    if (filter.query.trim().isNotEmpty) {
      where.add('(title LIKE ? OR author LIKE ? OR summary LIKE ?)');
      final q = '%${filter.query.trim()}%';
      args.addAll([q, q, q]);
    }
    final sql = '''
      SELECT * FROM work
      WHERE ${where.join(' AND ')}
      ORDER BY
        CASE script WHEN 'kai' THEN 0 WHEN 'xing' THEN 1 WHEN 'cao' THEN 2
                    WHEN 'li' THEN 3 WHEN 'zhuan' THEN 4 ELSE 5 END,
        dynasty, title
      LIMIT $limit
    ''';
    return _db.raw.select(sql, args).map(Work.fromRow).toList();
  }

  Work? work(String id) {
    final rows = _db.raw.select('SELECT * FROM work WHERE id = ?', [id]);
    return rows.isEmpty ? null : Work.fromRow(rows.first);
  }

  List<WorkImage> images(String workId) {
    final rows = _db.raw.select(
      'SELECT * FROM work_image WHERE work_id = ? ORDER BY seq',
      [workId],
    );
    return rows.map(WorkImage.fromRow).toList();
  }

  List<Person> persons() {
    final rows = _db.raw.select(
      'SELECT * FROM person WHERE work_count > 0 ORDER BY work_count DESC, name',
    );
    return rows.map(Person.fromRow).toList();
  }

  List<String> distinct(String column) {
    final rows = _db.raw.select(
      "SELECT DISTINCT $column AS v FROM work "
      "WHERE excluded = 0 AND $column IS NOT NULL AND $column != '' "
      "ORDER BY v",
    );
    return rows.map((r) => r['v'] as String).toList();
  }

  int count() {
    final r = _db.raw.select('SELECT COUNT(*) AS n FROM work WHERE excluded = 0');
    return r.first['n'] as int;
  }
}
