import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc("demo_user")
        .collection("data")
        .doc("profile")
        .get();

    if (!doc.exists || doc.data() == null) {
      return {};
    }

    return doc.data()!;
  }
}