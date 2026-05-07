import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class DriverState extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Variables

  bool isAvailable = false;

  bool hasActiveEmergency = false;

  String currentEmergency = "No Active Request";

  String status = "Offline";

  double eta = 0.0;

  Map<String, dynamic>? activeRequestData;

  // Profile Data Getters

  String driverName = "Loading...";

  String ambulanceId = "---";

  // Notification Data

  bool showNotification = false;

  String notificationMsg = "";

  DriverState() {
    _init();
  }

  void _init() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    // Realtime listener for ASSIGNED requests

    _supabase
        .from('emergency_requests')
        .stream(primaryKey: ['id'])
        .eq('assigned_driver_id', user.id) // Filter by Driver ID
        .listen((List<Map<String, dynamic>> data) {
          print("Realtime Data Received for Driver: $data");

          // Check if there is an active assigned/on_progress request

          final active = data.firstWhere(
            (req) =>
                req['status'] == 'driver_assigned' ||
                req['status'] == 'on_the_way' ||
                req['status'] == 'reached_patient' ||
                req['status'] == 'patient_onboard',

            orElse: () => {},
          );

          if (active.isNotEmpty) {
            hasActiveEmergency = true;

            currentEmergency = active['citizen_name'] ?? "Emergency";

            activeRequestData = active;

            notifyListeners();
          } else {
            hasActiveEmergency = false;

            activeRequestData = null;

            notifyListeners();
          }
        });
  }

  // UI Toggle for Availability

  Future<void> toggleAvailability(bool value) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      print("Toggle Error: No user logged in");

      return;
    }

    // Pehle UI update kar dete hain taaki user ko fast feel ho

    isAvailable = value;

    status = value ? "Available" : "Offline";

    notifyListeners();

    try {
      final newStatus = value ? 'available' : 'offline';

      // Database update call

      await _supabase
          .from('drivers')
          .update({'status': newStatus})
          .eq('id', user.id);

      print("✅ Status successfully updated in Database to: $newStatus");
    } catch (e) {
      // Agar fail ho jaye toh purane status par wapas le aao

      isAvailable = !value;

      status = isAvailable ? "Available" : "Offline";

      notifyListeners();

      print("❌ Toggle Database Error: $e");
    }
  }

  // --- NEW METHODS TO FIX ERRORS ---

  // Map Screen ke liye status update (Reached Scene, Patient Onboard etc.)

  // DriverState ke updateStatus mein ye ensure karo
  Future<void> fetchOngoingTask() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await _supabase
          .from('emergency_requests')
          .select()
          .eq('assigned_driver_id', user.id)
      // Hum un statuses ko check kar rahe hain jo 'active' hain
          .filter('status', 'in', '("driver_assigned","on_the_way","reached_patient","patient_onboard")')
          .maybeSingle();

      if (res != null) {
        hasActiveEmergency = true;
        currentEmergency = res['citizen_name'] ?? "Emergency";
        activeRequestData = res;
      } else {
        hasActiveEmergency = false;
        activeRequestData = null;
      }
      notifyListeners();
    } catch (e) {
      print("Fetch Ongoing Task Error: $e");
    }
  }

  Future<void> updateStatus(String newStatus) async {
    if (activeRequestData == null) return;

    try {
      await _supabase
          .from('emergency_requests')
          .update({
            'status': newStatus,
          }) // 'newStatus' ki value SQL list se match honi chahiye
          .eq('id', activeRequestData!['id']);

      // UI update ke liye

      notifyListeners();

      print("✅ Status Updated to: $newStatus");
    } catch (e) {
      print("❌ Update Error: $e");
    }
  }

  // Emergency complete hone par clear karna

  Future<void> clearEmergency() async {
    if (activeRequestData == null) return;

    try {
      await _supabase
          .from('emergency_requests')
          .update({'status': 'completed'})
          .eq('id', activeRequestData!['id']);

      hasActiveEmergency = false;

      activeRequestData = null;

      notifyListeners();
    } catch (e) {
      print("Clear Emergency Error: $e");
    }
  }

  // Notification clear karne ke liye

  void clearNotification() {
    showNotification = false;

    notificationMsg = "";

    notifyListeners();
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
