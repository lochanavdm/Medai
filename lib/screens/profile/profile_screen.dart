import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: "Demo Patient",
  );
  final TextEditingController _ageController = TextEditingController(
    text: "23",
  );
  final TextEditingController _bloodTypeController = TextEditingController(
    text: "O+",
  );
  final TextEditingController _allergiesController = TextEditingController(
    text: "Penicillin",
  );
  final TextEditingController _customConditionController =
      TextEditingController();

  final List<String> _conditionOptions = [
    "Diabetes",
    "Hypertension",
    "Asthma",
    "Kidney Disease",
    "Heart Disease",
  ];

  final List<String> _selectedConditions = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
    });
  }

  void _addCustomCondition() {
    final text = _customConditionController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (!_selectedConditions.contains(text)) {
        _selectedConditions.add(text);
      }
      _customConditionController.clear();
    });
  }

  Future<void> _saveProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc("demo_user")
          .collection("data")
          .doc("profile")
          .set({
            "name": _nameController.text.trim(),
            "age": _ageController.text.trim(),
            "bloodType": _bloodTypeController.text.trim(),
            "allergies": _allergiesController.text.trim(),
            "healthConditions": _selectedConditions,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile saved")));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    }
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc("demo_user")
          .collection("data")
          .doc("profile")
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      setState(() {
        _nameController.text = data["name"] ?? "";
        _ageController.text = data["age"] ?? "";
        _bloodTypeController.text = data["bloodType"] ?? "";
        _allergiesController.text = data["allergies"] ?? "";

        _selectedConditions.clear();
        _selectedConditions.addAll(
          List<String>.from(data["healthConditions"] ?? []),
        );
      });
    } catch (_) {}
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
    );
  }

  Widget _inputCard({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.deepPurple),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: type,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: title,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    final selected = _selectedConditions.contains(text);

    return GestureDetector(
      onTap: () => _toggleCondition(text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.tealAccent.shade400 : AppColors.background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              left: 24,
              right: 24,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.lightPurple],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
            child: const Column(
              children: [
                Icon(Icons.person_pin_circle, color: Colors.white, size: 52),
                SizedBox(height: 10),
                Text(
                  "Medical Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Manage your health details securely",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _sectionTitle("Personal Details"),

                  _inputCard(
                    title: "Patient Name",
                    icon: Icons.person,
                    controller: _nameController,
                  ),

                  _inputCard(
                    title: "Age",
                    icon: Icons.cake,
                    controller: _ageController,
                    type: TextInputType.number,
                  ),

                  _inputCard(
                    title: "Blood Type",
                    icon: Icons.bloodtype,
                    controller: _bloodTypeController,
                  ),

                  _inputCard(
                    title: "Allergies",
                    icon: Icons.warning_amber_rounded,
                    controller: _allergiesController,
                  ),

                  _sectionTitle("Health Conditions"),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _conditionOptions
                              .map((e) => _chip(e))
                              .toList(),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customConditionController,
                                decoration: InputDecoration(
                                  hintText: "Add custom condition",
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: _addCustomCondition,
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.pinkAccent,
                                size: 34,
                              ),
                            ),
                          ],
                        ),

                        if (_selectedConditions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _selectedConditions.join(", "),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Save Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    AppConstants.medicalDisclaimer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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
}
