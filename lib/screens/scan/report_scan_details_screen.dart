import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../ai_chat/ai_chat_screen.dart';

class ReportScanDetailsScreen extends StatelessWidget {
  final String reportType;
  final String summary;
  final String findings;
  final String warnings;
  final String recommendations;
  final String rawText;

  const ReportScanDetailsScreen({
    super.key,
    required this.reportType,
    required this.summary,
    required this.findings,
    required this.warnings,
    required this.recommendations,
    required this.rawText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description_rounded, color: Colors.white, size: 38),
                SizedBox(height: 14),
                Text(
                  "Report Analysis",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "AI-powered medical report summary",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _heroCard(),
                  const SizedBox(height: 16),

                  _infoCard(
                    icon: Icons.summarize_rounded,
                    title: "Summary",
                    content: summary,
                  ),
                  _infoCard(
                    icon: Icons.analytics_rounded,
                    title: "Key Findings",
                    content: findings,
                  ),
                  _infoCard(
                    icon: Icons.warning_amber_rounded,
                    title: "Warnings",
                    content: warnings,
                    warning: true,
                  ),
                  _infoCard(
                    icon: Icons.recommend_rounded,
                    title: "Recommendations",
                    content: recommendations,
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final reportMessage =
                            """
Analyze this medical report:

Report Type: $reportType

Summary: $summary

Key Findings: $findings

Warnings: $warnings

Recommendations: $recommendations

Explain clearly and answer user questions.
""";

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AiChatScreen(initialMessage: reportMessage),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Discuss This Report"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(26),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Detected Report Type",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  reportType.isEmpty ? "Medical Report" : reportType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String content,
    bool warning = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: warning ? Border.all(color: Colors.orange.shade200) : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: warning ? Colors.orange : Colors.deepPurple),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: warning ? Colors.orange : Colors.deepPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  content.isEmpty ? "Not available" : content,
                  style: const TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
