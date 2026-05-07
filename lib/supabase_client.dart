import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://ktohatmnprrvnenaakya.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0b2hhdG1ucHJydm5lbmFha3lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzIwMDEsImV4cCI6MjA5MDgwODAwMX0.RFfUEd-QicTuPG0Yo8iGDoiKBzGtUGi2-rvm1MamJUQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}