import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryService {
  static final List<HistoryItem> _historyList = [];
  static const String _historyKey = "history_items";

  static Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);

    if (historyJson == null) return;

    final List<dynamic> decodedList = jsonDecode(historyJson);

    _historyList.clear();
    _historyList.addAll(
      decodedList.map((item) => HistoryItem.fromJson(item)).toList(),
    );
  }

  static Future<void> addHistory(HistoryItem item) async {
    _historyList.insert(0, item);
    await _saveHistory();

    await FirebaseFirestore.instance
        .collection("users")
        .doc("demo_user")
        .collection("history")
        .add(item.toJson());
  }

  static Future<void> deleteHistoryAt(int index) async {
    if (index < 0 || index >= _historyList.length) return;

    _historyList.removeAt(index);
    await _saveHistory();
  }

  static List<HistoryItem> getHistory() {
    return _historyList;
  }

  static Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedList = _historyList.map((item) => item.toJson()).toList();

    await prefs.setString(_historyKey, jsonEncode(encodedList));
  }
}
