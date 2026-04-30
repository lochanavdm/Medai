class HistoryItem {
  final String type; // "Medicine" or "Report"
  final String title;
  final String summary;
  final DateTime dateTime;

  // Medicine details
  final String dosage;
  final String medicineWarnings;
  final String usage;

  // Report details
  final String findings;
  final String reportWarnings;
  final String recommendations;

  HistoryItem({
    required this.type,
    required this.title,
    required this.summary,
    required this.dateTime,
    this.dosage = "",
    this.medicineWarnings = "",
    this.usage = "",
    this.findings = "",
    this.reportWarnings = "",
    this.recommendations = "",
  });

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "title": title,
      "summary": summary,
      "dateTime": dateTime.toIso8601String(),
      "dosage": dosage,
      "medicineWarnings": medicineWarnings,
      "usage": usage,
      "findings": findings,
      "reportWarnings": reportWarnings,
      "recommendations": recommendations,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      type: json["type"] ?? "",
      title: json["title"] ?? "",
      summary: json["summary"] ?? "",
      dateTime: DateTime.parse(json["dateTime"]),
      dosage: json["dosage"] ?? "",
      medicineWarnings: json["medicineWarnings"] ?? "",
      usage: json["usage"] ?? "",
      findings: json["findings"] ?? "",
      reportWarnings: json["reportWarnings"] ?? "",
      recommendations: json["recommendations"] ?? "",
    );
  }
}
