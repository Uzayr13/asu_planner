import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key/value store for all user-entered text and toggles.
/// Keys: day:2027-01-04 | wk:<mondayKey>:p0..p2 | wk:<mondayKey>:d0..d6 |
/// habit:<mondayKey>:0..6 | note:<page>:<line> | word:<row>:<col>
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
}
