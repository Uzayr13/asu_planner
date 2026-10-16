import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key/value store for all user-entered text and toggles.
///
/// Keys, exactly as the pages construct them (see `dateKey` in
/// `data/calendar_math.dart` for the zero-padded YYYY-MM-DD form):
///
///   day:<date>            day note, shared by month/week/day views
///   dv:<date>:p0..2       day priorities (text)
///   dvf:<date>:0..2       day priority checkboxes (bool)
///   dv:<date>:h6..h21     schedule slots (text)
///   dv:<date>:word        one Arabic word today (text)
///   habit:<monday>:0..6   habit dots (bool)
///   wk:<week>:p0..2       week priorities (text)
///   prio:<week>:0..2      week priority checkboxes (bool)
///   note:<page>:<line>    notes pages, page 1..2, line 0..19
///   word:<row>:<col>      vocabulary table, 13 rows x 4 cols
///
/// Text and flags are stored in separate SharedPreferences buckets — reading
/// a flag key with `getString` throws. Anything that serialises the store must
/// carry that distinction along; see `lib/backup/backup.dart`.
class Store extends ChangeNotifier {
  Store._(this._p);
  final SharedPreferences _p;

  static Future<Store> open() async => Store._(await SharedPreferences.getInstance());

  String text(String key) => _p.getString(key) ?? '';
  bool flag(String key) => _p.getBool(key) ?? false;

  Future<void> setText(String key, String v) async {
    if (v.isEmpty) {
      await _p.remove(key);
    } else {
      await _p.setString(key, v);
    }
    notifyListeners();
  }

  Future<void> setFlag(String key, bool v) async {
    await _p.setBool(key, v);
    notifyListeners();
  }

  /// Everything currently stored, keyed as-is.
  ///
  /// Only `String` and `bool` values are included; anything else is skipped
  /// rather than cast, so a stray non-plannable entry can never poison an
  /// export. Empty text is already absent — `setText('')` removes the key.
  Map<String, Object> dump() {
    final out = <String, Object>{};
    for (final key in _p.getKeys()) {
      final v = _p.get(key);
      // Separate branches so Dart promotes each to a non-nullable Object;
      // `v is String || v is bool` promotes to neither.
      if (v is String) {
        out[key] = v;
      } else if (v is bool) {
        out[key] = v;
      }
    }
    return out;
  }

  /// Write [values], dispatching on each value's runtime type.
  ///
  /// Goes through [setText]/[setFlag] so the remove-on-empty rule stays
  /// consistent. Notifies once at the end rather than per key, so a large
  /// import does not thrash every listening widget.
  ///
  /// Values that are neither `String` nor `bool` are ignored, not cast —
  /// a hand-edited backup must not crash the app.
  Future<void> applyAll(Map<String, Object> values) async {
    for (final entry in values.entries) {
      final v = entry.value;
      if (v is bool) {
        await _p.setBool(entry.key, v);
      } else if (v is String) {
        if (v.isEmpty) {
          await _p.remove(entry.key);
        } else {
          await _p.setString(entry.key, v);
        }
      }
    }
    notifyListeners();
  }
}
