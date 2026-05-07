import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/driver_state.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.darkBg,
      ),
      body: Consumer<DriverState>(
        builder: (context, driverState, child) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.red.withOpacity(0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Icon(Icons.person, size: 80, color: AppTheme.red),
              ),
              const SizedBox(height: 32),

              // Driver Info Cards
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: AppTheme.red),
                  title: const Text('Name'),
                  subtitle: Text(driverState.driverName),
                  trailing: const Icon(Icons.edit),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_hospital, color: AppTheme.red),
                  title: const Text('Ambulance ID'),
                  subtitle: Text(driverState.ambulanceId),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.circle,
                    color: driverState.status == 'Available'
                        ? Colors.green : Colors.orange,
                  ),
                  title: const Text('Status'),
                  subtitle: Text(driverState.status),
                ),
              ),
              const Spacer(),
              // Shift Toggle
              ElevatedButton.icon(
                icon: const Icon(Icons.power_settings_new),
                label: const Text('End Shift'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: () {
                  driverState.toggleAvailability(false);
                  Navigator.pop(context); // Shift end karke dashboard wapas
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
