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
      // 1. Data prepare karo
      final updateData = {
        'status': newStatus,
      };

      // 2. Agar status completed hai, toh Hospital details add karo
      if (newStatus == 'completed') {
        updateData['hospital_id'] = activeRequestData!['hospital_id'];
        updateData['hospital_name'] = activeRequestData!['hospital_name'];
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      // 3. Database update
      await _supabase
          .from('emergency_requests')
          .update(updateData)
          .eq('id', activeRequestData!['id']);

      notifyListeners();
    } catch (e) {
      print("Update Error: $e");
    }
  }

  Future<void> clearEmergency() async {
    if (activeRequestData == null) return;

    try {
      // 1. Pehle check karo ki activeRequestData mein hospital_id hai ya nahi
      print("DEBUG: Active Hospital ID is: ${activeRequestData!['hospital_id']}");

      // 2. Emergency Requests table ko update karo
      await _supabase
          .from('emergency_requests')
          .update({
        'status': 'completed',
        'hospital_id': activeRequestData!['hospital_id'],   // ✅ ID pass karo
        'hospital_name': activeRequestData!['hospital_name'], // ✅ Name pass karo
      })
          .eq('id', activeRequestData!['id']);

      // 3. Agar aap direct records table mein insert kar rahe ho toh wahan bhi bhenjo
      // (Aapke case mein ye database trigger se ho raha hoga ya finish button se)

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
