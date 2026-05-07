import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'theme.dart';
import 'provider/theme_provider.dart';
import 'provider/driver_state.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Initialize
  await SupabaseConfig.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DriverState()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CureAsap Driver',
      // Yahan hum tumhare AppTheme class ka darkTheme function call kar rahe hain
      theme: ThemeData.light(), // Agar light theme ka code nahi hai toh default use karega
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeProvider.themeMode,
      home: const LoginScreen(),
    );
  }
}