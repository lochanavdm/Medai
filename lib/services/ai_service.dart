import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String apiKey = "";

  static Future<String> analyzeMedicine(String text) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a professional medical assistant.\n\n"
                "Answer the user's question in a clear, simple, and helpful way.\n"
                "Do NOT use structured format unless explicitly asked.\n"
                "Explain in natural human language.\n"
                "Always include a short safety warning if needed.",
          },
          {"role": "user", "content": text},
        ],
        "temperature": 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["choices"][0]["message"]["content"].toString().trim();
    } else {
      print("===== CHAT ERROR =====");
      print(response.body);
      return "Sorry, I could not answer right now. Please try again.";
    }
  }

  static Future<String> analyzeMedicineStructured(
    String text, {
    Map<String, dynamic>? profile,
  }) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final allergies = profile?["allergies"] ?? "Not provided";
    final healthConditions =
        (profile?["healthConditions"] as List?)?.join(", ") ?? "Not provided";

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a professional medical assistant.\n\n"
                "User Medical Profile:\n"
                "Allergies: $allergies\n"
                "Health Conditions: $healthConditions\n\n"
                "Analyze the scanned medicine text.\n"
                "Consider allergy and health condition conflicts.\n\n"
                "Return ONLY in this exact plain text format:\n"
                "Medicine: value\n"
                "Dosage: value\n"
                "Warnings: value\n"
                "Usage: value\n\n"
                "Rules:\n"
                "- No markdown\n"
                "- No ** symbols\n"
                "- No bullet points\n"
                "- If unknown, write Unknown\n"
                "- Keep warnings clear and short\n",
          },
          {"role": "user", "content": text},
        ],
        "temperature": 0.2,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["choices"][0]["message"]["content"]
          .toString()
          .replaceAll("**", "")
          .trim();
    } else {
      print("===== MEDICINE SCAN ERROR =====");
      print(response.body);

      return "Medicine: Unknown\n"
          "Dosage: Unknown\n"
          "Warnings: Unknown\n"
          "Usage: Unknown";
    }
  }

  static Future<String> analyzeReportStructured(String text) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a medical AI assistant.\n\n"
                "The user scanned a medical report which may contain tables and lab values.\n\n"
                "Your job:\n"
                "- Understand the report even if it is table-based\n"
                "- Extract important medical meaning\n"
                "- Explain in simple human language\n\n"
                "Return STRICTLY in this format:\n\n"
                "Report Type:\n"
                "Summary:\n"
                "Key Findings:\n"
                "Warnings:\n"
                "Recommendations:\n\n"
                "Rules:\n"
                "- NEVER write 'Not available' unless absolutely no data\n"
                "- If values are present, explain them\n"
                "- Convert table data into readable explanation\n"
                "- Keep answers simple and useful\n"
                "- No markdown\n",
          },
          {"role": "user", "content": text},
        ],
        "temperature": 0.2,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["choices"][0]["message"]["content"]
          .toString()
          .replaceAll("**", "")
          .trim();
    } else {
      print("===== REPORT ERROR =====");
      print(response.body);

      return "Report Type: Unknown\n"
          "Summary: Unable to analyze\n"
          "Key Findings: Unknown\n"
          "Warnings: Unknown\n"
          "Recommendations: Unknown";
    }
  }

  static Future<String> analyzeSymptomsForDoctor(String symptoms) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a medical assistant. Analyze the user's symptoms and return STRICTLY in this format:\n\n"
                "Recommended Specialist:\n"
                "Urgency:\n"
                "Advice:\n"
                "Emergency Warning:\n\n"
                "Rules:\n"
                "- Be detailed but clear\n"
                "- If symptoms may need urgent care, mention it clearly\n"
                "- Do not add extra headings\n"
                "- Do not diagnose with certainty\n",
          },
          {"role": "user", "content": symptoms},
        ],
        "temperature": 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["choices"][0]["message"]["content"]
          .toString()
          .replaceAll("**", "")
          .trim();
    } else {
      print("===== DOCTOR AI ERROR =====");
      print(response.body);

      return "Recommended Specialist: General Physician\n"
          "Urgency: Normal\n"
          "Advice: Please consult a doctor for proper medical evaluation.\n"
          "Emergency Warning: Not available";
    }
  }

  static Future<List<Map<String, String>>> fetchNearbyMedicalPlaces({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse("https://overpass-api.de/api/interpreter");

    final query =
        """
[out:json];
(
  node["amenity"="hospital"](around:5000,$latitude,$longitude);
  node["amenity"="clinic"](around:5000,$latitude,$longitude);
  way["amenity"="hospital"](around:5000,$latitude,$longitude);
  way["amenity"="clinic"](around:5000,$latitude,$longitude);
  relation["amenity"="hospital"](around:5000,$latitude,$longitude);
  relation["amenity"="clinic"](around:5000,$latitude,$longitude);
);
out center;
""";

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Accept": "application/json",
        "User-Agent": "MedAI Flutter App",
      },
      body: "data=${Uri.encodeComponent(query)}",
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final elements = data["elements"] as List<dynamic>;

      return elements.map<Map<String, String>>((element) {
        final tags = element["tags"] ?? {};
        final lat = element["lat"] ?? element["center"]?["lat"];
        final lon = element["lon"] ?? element["center"]?["lon"];

        return {
          "name": (tags["name"] ?? "Unnamed Place").toString(),
          "type": (tags["amenity"] ?? "medical").toString(),
          "distance": "",
          "address": [
            tags["addr:street"],
            tags["addr:city"],
            tags["addr:suburb"],
          ].where((e) => e != null && e.toString().isNotEmpty).join(", "),
          "lat": lat?.toString() ?? "",
          "lon": lon?.toString() ?? "",
        };
      }).toList();
    } else {
      print("===== OVERPASS ERROR =====");
      print(response.body);
      return [];
    }
  }
}
