import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/ai_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _symptomController = TextEditingController();

  final List<String> _symptomChips = [
    "Fever",
    "Cough",
    "Headache",
    "Chest Pain",
    "Diabetes",
    "Stomach Pain",
  ];

  final List<String> _selectedSymptoms = [];
  String _recommendedSpecialist = "";
  String _urgency = "";
  String _advice = "";
  String _emergencyWarning = "";
  bool _isAnalyzing = false;

  String _currentLocation = "Location not fetched yet";

  double? _currentLat;
  double? _currentLng;

  List<Map<String, String>> _nearbyPlaces = [
    {
      "name": "City Care Hospital",
      "type": "Hospital",
      "distance": "2.1 km away",
      "address": "Main Street, Colombo",
    },
    {
      "name": "MediPlus Clinic",
      "type": "Clinic",
      "distance": "1.4 km away",
      "address": "Galle Road, Colombo",
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _toggleSymptom(String symptom) {
    if (!mounted) return;
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  Map<String, String> _parseDoctorResponse(String response) {
    String extract(String key) {
      final parts = response.split(RegExp("$key[:\\-]*", caseSensitive: false));
      if (parts.length > 1) {
        return parts[1].split('\n')[0].trim();
      }
      return "";
    }

    return {
      "specialist": extract("Recommended Specialist"),
      "urgency": extract("Urgency"),
      "advice": extract("Advice"),
      "warning": extract("Emergency Warning"),
    };
  }

  Future<void> _analyzeSymptoms() async {
    final typedText = _symptomController.text.trim();
    final chipText = _selectedSymptoms.join(", ");

    String combinedSymptoms = "";

    if (typedText.isNotEmpty && chipText.isNotEmpty) {
      combinedSymptoms = "$typedText, $chipText";
    } else if (typedText.isNotEmpty) {
      combinedSymptoms = typedText;
    } else if (chipText.isNotEmpty) {
      combinedSymptoms = chipText;
    }

    if (combinedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter or select symptoms")),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isAnalyzing = true;
    });

    final aiResponse = await AIService.analyzeSymptomsForDoctor(
      combinedSymptoms,
    );
    final parsed = _parseDoctorResponse(aiResponse);

    if (!mounted) return;
    setState(() {
      _recommendedSpecialist = parsed["specialist"] ?? "";
      _urgency = parsed["urgency"] ?? "";
      _advice = parsed["advice"] ?? "";
      _emergencyWarning = parsed["warning"] ?? "";
      _isAnalyzing = false;
    });
  }

  Future<void> _openInMaps(Map<String, String> place) async {
    final lat = place["lat"];
    final lon = place["lon"];

    if (lat == null || lon == null || lat.isEmpty || lon.isEmpty) return;

    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lon",
    );

    final bool launched = await launchUrl(
      googleMapsUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      final bool browserLaunched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.platformDefault,
      );

      if (!browserLaunched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No maps or browser app found")),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    print("GET LOCATION CALLED");

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        _currentLocation = "Location services are disabled";
      });
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _currentLocation = "Location permission denied";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _currentLocation = "Location permission permanently denied";
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print(position.latitude);
    print(position.longitude);

    if (!mounted) return;
    setState(() {
      _currentLat = position.latitude;
      _currentLng = position.longitude;
      _currentLocation =
          "Lat: ${position.latitude.toStringAsFixed(4)}, "
          "Lng: ${position.longitude.toStringAsFixed(4)}";
    });

    await _fetchNearbyPlaces();
  }

  Future<void> _fetchNearbyPlaces() async {
    if (_currentLat == null || _currentLng == null) return;

    final places = await AIService.fetchNearbyMedicalPlaces(
      latitude: _currentLat!,
      longitude: _currentLng!,
    );

    for (final place in places) {
      final lat = double.tryParse(place["lat"] ?? "");
      final lon = double.tryParse(place["lon"] ?? "");

      if (lat != null && lon != null) {
        final meters = Geolocator.distanceBetween(
          _currentLat!,
          _currentLng!,
          lat,
          lon,
        );

        final km = meters / 1000;
        place["distance"] = "${km.toStringAsFixed(1)} km away";
      } else {
        place["distance"] = "Distance unavailable";
      }
    }

    if (!mounted) return;
    setState(() {
      _nearbyPlaces.clear();
      _nearbyPlaces.addAll(places);
    });
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
              left: 20,
              right: 20,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.lightPurple],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nearby Doctors",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Describe symptoms and find the right care",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Enter Symptoms",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _symptomController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                "Example: fever, cough, chest pain, weakness...",
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Quick Select",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _symptomChips.map((symptom) {
                            final selected = _selectedSymptoms.contains(
                              symptom,
                            );

                            return GestureDetector(
                              onTap: () => _toggleSymptom(symptom),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.tealAccent.shade400
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  symptom,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _analyzeSymptoms,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Find Nearby Doctors",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Recommended Results",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_isAnalyzing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    _buildPlaceholderCard(
                      title: _recommendedSpecialist.isEmpty
                          ? "Doctor recommendations will appear here"
                          : "Recommended Specialist: $_recommendedSpecialist",
                      subtitle: _recommendedSpecialist.isEmpty
                          ? "AI analysis will appear after you enter symptoms"
                          : "Best doctor type based on symptoms",
                      icon: Icons.local_hospital,
                    ),
                    const SizedBox(height: 12),
                    _buildPlaceholderCard(
                      title: _urgency.isEmpty
                          ? "Urgency will appear here"
                          : "Urgency: $_urgency",
                      subtitle: _urgency.isEmpty
                          ? "AI will estimate urgency level"
                          : "How soon you should seek care",
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildPlaceholderCard(
                      title: _advice.isEmpty
                          ? "Advice will appear here"
                          : "Advice",
                      subtitle: _advice.isEmpty
                          ? "Basic care advice will appear here"
                          : _advice,
                      icon: Icons.medical_information,
                    ),
                    const SizedBox(height: 12),
                    _buildPlaceholderCard(
                      title: _emergencyWarning.isEmpty
                          ? "Emergency warning will appear here"
                          : "Emergency Warning",
                      subtitle: _emergencyWarning.isEmpty
                          ? "Critical warning will appear here if needed"
                          : _emergencyWarning,
                      icon: Icons.emergency,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Current Location",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.pinkAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _currentLocation,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    const Text(
                      "Nearby Map",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: (_currentLat == null || _currentLng == null)
                            ? const Center(
                                child: Text(
                                  "Map will appear after location is fetched",
                                ),
                              )
                            : FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    _currentLat!,
                                    _currentLng!,
                                  ),
                                  initialZoom: 13,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                    userAgentPackageName: "com.example.medai",
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      // User location
                                      Marker(
                                        point: LatLng(
                                          _currentLat!,
                                          _currentLng!,
                                        ),
                                        width: 50,
                                        height: 50,
                                        child: const Icon(
                                          Icons.my_location,
                                          color: Colors.blue,
                                          size: 34,
                                        ),
                                      ),

                                      // Nearby hospitals / clinics
                                      ..._nearbyPlaces
                                          .where((place) {
                                            return (place["lat"] ?? "")
                                                    .isNotEmpty &&
                                                (place["lon"] ?? "").isNotEmpty;
                                          })
                                          .map((place) {
                                            return Marker(
                                              point: LatLng(
                                                double.tryParse(
                                                      place["lat"] ?? "",
                                                    ) ??
                                                    0,
                                                double.tryParse(
                                                      place["lon"] ?? "",
                                                    ) ??
                                                    0,
                                              ),
                                              width: 50,
                                              height: 50,
                                              child: GestureDetector(
                                                onTap: () {
                                                  _showPlaceDetails(place);
                                                },
                                                child: Icon(
                                                  (place["type"] ?? "")
                                                              .toLowerCase() ==
                                                          "hospital"
                                                      ? Icons.local_hospital
                                                      : Icons.medical_services,
                                                  color: Colors.red,
                                                  size: 34,
                                                ),
                                              ),
                                            );
                                          }),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const Text(
                      "Nearby Hospitals & Clinics",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._nearbyPlaces.map((place) {
                      return _buildPlaceCard(
                        name: place["name"] ?? "",
                        type: place["type"] ?? "",
                        distance: place["distance"] ?? "",
                        address: place["address"] ?? "",
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard({
    required String name,
    required String type,
    required String distance,
    required String address,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              type.toLowerCase() == "hospital"
                  ? Icons.local_hospital
                  : Icons.medical_services,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$type • $distance",
                  style: const TextStyle(
                    color: Colors.brown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(address, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceDetails(Map<String, String> place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                place["name"] ?? "Unknown Place",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Type: ${place["type"] ?? "medical"}",
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                "Distance: ${place["distance"] ?? "Unknown"}",
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                "Address: ${(place["address"] ?? "").isEmpty ? "Not available" : place["address"]}",
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _openInMaps(place);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Open in Maps",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
