import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:medai/utils/app_colors.dart';
import 'package:medai/services/ai_service.dart';
import 'package:medai/screens/scan/scan_details_screen.dart';
import 'report_scan_details_screen.dart';
import '../../services/history_service.dart';
import '../../models/history_item.dart';
import '../../services/profile_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  int _selectedTab = 0; // 0 = Medicine, 1 = Report

  XFile? _selectedImage;
  String _extractedText = "";

  Future<void> _openCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedImage = image;
        _isLoading = true; // 🔥 start loading
      });

      await _extractText(image.path);

      final profile = await ProfileService.getProfile();

      String aiResponse = await AIService.analyzeMedicineStructured(
        _extractedText,
        profile: profile,
      );

      final parsedData = _parseAIResponse(aiResponse);

      HistoryService.addHistory(
        HistoryItem(
          type: "Medicine",
          title: parsedData["medicine"] ?? "Unknown Medicine",
          summary: parsedData["usage"] ?? "No details",
          dateTime: DateTime.now(),
        ),
      );

      setState(() {
        _isLoading = false; // 🔥 stop loading
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanDetailsScreen(
            medicineName: parsedData["medicine"] ?? "",
            dosage: parsedData["dosage"] ?? "",
            warnings: parsedData["warnings"] ?? "",
            usage: parsedData["usage"] ?? "",
          ),
        ),
      );
    }
  }

  Future<void> _openGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
        _isLoading = true; // 🔥 start loading
      });

      await _extractText(image.path);

      String aiResponse;

      if (_selectedTab == 0) {
        // 🔷 Medicine
        final profile = await ProfileService.getProfile();

        aiResponse = await AIService.analyzeMedicineStructured(
          _extractedText,
          profile: profile,
        );

        final parsedData = _parseAIResponse(aiResponse);

        final medicineTitle = parsedData["medicine"] ?? "";
        final medicineSummary = parsedData["usage"] ?? "";

        if (medicineTitle.isNotEmpty &&
            medicineTitle.toLowerCase() != "not applicable" &&
            medicineTitle.toLowerCase() != "unknown medicine") {
          HistoryService.addHistory(
            HistoryItem(
              type: "Medicine",
              title: medicineTitle,
              summary: medicineSummary.isEmpty ? "No details" : medicineSummary,
              dateTime: DateTime.now(),
            ),
          );
        }

        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanDetailsScreen(
              medicineName: parsedData["medicine"] ?? "",
              dosage: parsedData["dosage"] ?? "",
              warnings: parsedData["warnings"] ?? "",
              usage: parsedData["usage"] ?? "",
            ),
          ),
        );
      } else {
        // 🔷 Report
        aiResponse = await AIService.analyzeReportStructured(_extractedText);

        setState(() {
          _isLoading = false;
        });

        final reportData = _parseReportResponse(aiResponse);

        final reportTitle = reportData["reportType"] ?? "";
        final reportSummary = reportData["summary"] ?? "";

        if (reportTitle.isNotEmpty &&
            reportTitle.toLowerCase() != "not available" &&
            reportTitle.toLowerCase() != "unknown") {
          HistoryService.addHistory(
            HistoryItem(
              type: "Report",
              title: reportTitle,
              summary: reportSummary.isEmpty
                  ? "No summary available"
                  : reportSummary,
              dateTime: DateTime.now(),
            ),
          );
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScanDetailsScreen(
              reportType: reportData["reportType"] ?? "",
              summary: reportData["summary"] ?? "",
              findings: reportData["findings"] ?? "",
              warnings: reportData["warnings"] ?? "",
              recommendations: reportData["recommendations"] ?? "",
              rawText: _extractedText,
            ),
          ),
        );
      }

      setState(() {
        _isLoading = false; // 🔥 stop loading
      });
    }
  }

  Future<void> _extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();

    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    String extractedText = recognizedText.text;

    setState(() {
      _extractedText = extractedText;
    });

    print("===== OCR TEXT =====");
    print(extractedText);

    textRecognizer.close();
  }

  Map<String, String> _parseAIResponse(String response) {
    String medicine = "";
    String dosage = "";
    String warnings = "";
    String usage = "";

    String lower = response.toLowerCase();

    // 🔥 Medicine
    if (lower.contains("medicine")) {
      medicine =
          response
                  .split(RegExp(r"medicine[:\-]*", caseSensitive: false))
                  .length >
              1
          ? response
                .split(RegExp(r"medicine[:\-]*", caseSensitive: false))[1]
                .split('\n')[0]
                .trim()
          : "";
    }

    // 🔥 Dosage
    if (lower.contains("dosage")) {
      dosage =
          response.split(RegExp(r"dosage[:\-]*", caseSensitive: false)).length >
              1
          ? response
                .split(RegExp(r"dosage[:\-]*", caseSensitive: false))[1]
                .split('\n')[0]
                .trim()
          : "";
    }

    // 🔥 Warnings
    if (lower.contains("warnings")) {
      warnings =
          response
                  .split(RegExp(r"warnings[:\-]*", caseSensitive: false))
                  .length >
              1
          ? response
                .split(RegExp(r"warnings[:\-]*", caseSensitive: false))[1]
                .split('\n')[0]
                .trim()
          : "";
    }

    // 🔥 Usage
    if (lower.contains("usage")) {
      usage =
          response.split(RegExp(r"usage[:\-]*", caseSensitive: false)).length >
              1
          ? response
                .split(RegExp(r"usage[:\-]*", caseSensitive: false))[1]
                .split('\n')[0]
                .trim()
          : "";
    }

    return {
      "medicine": medicine,
      "dosage": dosage,
      "warnings": warnings,
      "usage": usage,
    };
  }

  Map<String, String> _parseReportResponse(String response) {
    String reportType = "";
    String summary = "";
    String findings = "";
    String warnings = "";
    String recommendations = "";

    String extract(String key) {
      final parts = response.split(RegExp("$key[:\\-]*", caseSensitive: false));
      if (parts.length > 1) {
        return parts[1].split('\n')[0].trim();
      }
      return "";
    }

    reportType = extract("Report Type");
    summary = extract("Summary");
    findings = extract("Key Findings");
    warnings = extract("Warnings");
    recommendations = extract("Recommendations");

    return {
      "reportType": reportType,
      "summary": summary,
      "findings": findings,
      "warnings": warnings,
      "recommendations": recommendations,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool isMedicine = _selectedTab == 0;

    Widget scanOption({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.deepPurple, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 60, 22, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.lightPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Smart Scan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isMedicine
                      ? "Scan medicine labels and get safety insights"
                      : "Scan medical reports and understand results",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: AppColors.cardShadow, blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: isMedicine
                              ? Colors.tealAccent.shade400
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Medicine",
                          style: TextStyle(
                            color: isMedicine ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: !isMedicine
                              ? Colors.tealAccent.shade400
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Report",
                          style: TextStyle(
                            color: !isMedicine ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _selectedImage == null
                  ? Column(
                      children: [
                        scanOption(
                          icon: Icons.camera_alt_rounded,
                          title: "Scan with Camera",
                          subtitle: isMedicine
                              ? "Take a photo of medicine label"
                              : "Capture a medical report",
                          onTap: _openCamera,
                        ),
                        scanOption(
                          icon: Icons.photo_library_rounded,
                          title: "Upload from Gallery",
                          subtitle: "Choose an image from your device",
                          onTap: _openGallery,
                        ),
                      ],
                    )
                  : _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            isMedicine
                                ? "Analyzing Medicine..."
                                : "Analyzing Report...",
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "AI is processing your scan",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.file(
                              File(_selectedImage!.path),
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              _extractedText.isEmpty
                                  ? "Processing text..."
                                  : _extractedText,
                              style: const TextStyle(height: 1.45),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                  _extractedText = "";
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Text(
                                "Scan Another Image",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
