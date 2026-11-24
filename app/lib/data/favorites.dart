import 'package:shared_preferences/shared_preferences.dart';

/// 生字本：本地收藏的字，持久化在 SharedPreferences。
class Favorites {
  Favorites._(this._prefs, this._chars);
  final SharedPreferences _prefs;
  final List<String> _chars;

  static Favorites? _instance;
  static Favorites get instance => _instance!;

  static Future<Favorites> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    final chars = prefs.getStringList('favorite_chars') ?? <String>[];
    _instance = Favorites._(prefs, List.of(chars));
    return _instance!;
  }

  List<String> get chars => List.unmodifiable(_chars);
  bool contains(String ch) => _chars.contains(ch);

  Future<bool> toggle(String ch) async {
    final added = !_chars.contains(ch);
    if (added) {
      _chars.insert(0, ch);
    } else {
      _chars.remove(ch);
    }
    await _prefs.setStringList('favorite_chars', _chars);
    return added;
  }

  Future<void> remove(String ch) async {
    _chars.remove(ch);
    await _prefs.setStringList('favorite_chars', _chars);
  }
}
