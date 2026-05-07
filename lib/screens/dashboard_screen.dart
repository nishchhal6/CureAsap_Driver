import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Sahi Relative Paths
import '../provider/driver_state.dart';
import '../provider/theme_provider.dart';
import '../theme.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          Consumer<DriverState>(
            builder: (context, state, _) => Row(
              children: [
                Text(
                  state.isAvailable ? 'Available' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: state.isAvailable
                        ? Colors.green
                        : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                Switch(
                  value: state.isAvailable,
                  activeColor: Colors.green,
                  onChanged: (v) => state.toggleAvailability(v),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: theme.drawerTheme.backgroundColor ?? theme.cardColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder(
              future: supabase.from('drivers').select().eq('id', user?.id ?? '').maybeSingle(),
              builder: (context, snapshot) {
                final driverData = snapshot.data as Map<String, dynamic>?;
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.red, Colors.red.shade700],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: AppTheme.red, size: 40),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          driverData?['name'] ?? 'Driver Name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          driverData?['vehicle'] ?? 'Vehicle No',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: theme.iconTheme.color?.withOpacity(0.85)),
              title: Text('Profile', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            const ThemeMenuTile(),
            ListTile(
              leading: Icon(Icons.settings, color: theme.iconTheme.color?.withOpacity(0.85)),
              title: Text('Settings', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context),
            ),
            Divider(color: theme.dividerColor, height: 24, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Provider context update
          await Provider.of<DriverState>(context, listen: false).fetchOngoingTask();
        },
        child: Consumer<DriverState>(
          builder: (context, state, _) {
            if (!state.hasActiveEmergency) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_hospital_outlined,
                        size: 64,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Wait for your next patient',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Pull down to check for updates", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }
            return _ActiveEmergencyView(state: state);
          },
        ),
      ),
    );
  }
}

class _ActiveEmergencyView extends StatelessWidget {
  final DriverState state;
  const _ActiveEmergencyView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String currentStatus = state.activeRequestData?['status'] ?? 'driver_assigned';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.red, Colors.red.shade600]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppTheme.red.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Emergency Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        currentStatus.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(state.currentEmergency, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(state.activeRequestData?['citizen_address'] ?? 'Location Fetching...', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text('Go to Navigation Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverMapScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 32),
          Text("UPDATE JOURNEY STATUS", style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 12),
          if (currentStatus == 'driver_assigned')
            _actionButton("Start Journey", Colors.orange, () => state.updateStatus('on_the_way')),
          if (currentStatus == 'on_the_way')
            _actionButton("Reached Patient Location", Colors.indigo, () => state.updateStatus('reached_patient')),
          if (currentStatus == 'reached_patient')
            _actionButton("Patient is Onboard", Colors.teal, () => state.updateStatus('patient_onboard')),
          if (currentStatus == 'patient_onboard')
            _actionButton("Trip Completed (Reached Hospital)", Colors.green, () => state.clearEmergency()),
          const SizedBox(height: 20),
          Card(
            color: theme.cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: AppTheme.red.withOpacity(0.12), child: const Icon(Icons.emergency, color: AppTheme.red)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency in Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Update status as you proceed so the patient and hospital can track you in real-time.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

void showLogoutDialog(BuildContext context) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<DriverState>().logout();
              Navigator.pop(dialogContext);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Yes, Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

class ThemeMenuTile extends StatelessWidget {
  const ThemeMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Change Theme',
      offset: const Offset(12, 0),
      color: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (ThemeMode mode) => context.read<ThemeProvider>().setTheme(mode),
      itemBuilder: (context) => [
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.light_mode_rounded, color: !isDark ? Colors.amber.shade700 : Colors.grey),
              const SizedBox(width: 12),
              Text('Light', style: TextStyle(fontWeight: !isDark ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.dark_mode_rounded, color: isDark ? AppTheme.red : Colors.grey),
              const SizedBox(width: 12),
              Text('Dark', style: TextStyle(fontWeight: isDark ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ],
      child: ListTile(
        leading: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
        title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(isDark ? 'Dark Mode' : 'Light Mode'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.red.withOpacity(0.12) : Colors.amber.withOpacity(0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isDark ? 'Dark' : 'Light',
            style: TextStyle(color: isDark ? AppTheme.red : Colors.amber.shade800, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ),
    );
  }
}