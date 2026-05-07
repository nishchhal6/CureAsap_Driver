import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/driver_state.dart';
import '../theme.dart';
import 'map_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.darkBg,
      ),
      body: Consumer<DriverState>(
        builder: (context, driverState, child) {
          if (!driverState.showNotification) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No new emergencies', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(driverState.notificationMsg, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.navigation),
                              label: const Text('Navigate'),
                              onPressed: () {
                                driverState.clearNotification();
                                // Navigate to map
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close),
                              label: const Text('Decline'),
                              // Navigate button ka code:
                              onPressed: () {
                                driverState.clearNotification();
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DriverMapScreen())
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
