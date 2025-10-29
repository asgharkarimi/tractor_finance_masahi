import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/farmer.dart';
import '../models/settings.dart';
import '../services/database_service.dart';
import 'farmer_detail_screen.dart';
import 'add_farmer_screen.dart';
import 'settings_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 32,
              width: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.agriculture, size: 32);
              },
            ),
            const SizedBox(width: 12),
            const Text('مدیریت درآمد تراکتور'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.getFarmersBox().listenable(),
        builder: (context, Box<Farmer> box, _) {
          final farmers = box.values.toList();

          if (farmers.isEmpty) {
            return const Center(
              child: Text(
                'هیچ کشاورزی ثبت نشده است',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ValueListenableBuilder(
            valueListenable: DatabaseService.getSettingsBox().listenable(),
            builder: (context, Box<Settings> settingsBox, _) {
              final settings = DatabaseService.getSettings();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: farmers.length,
                itemBuilder: (context, index) {
                  final farmer = farmers[index];
                  final totalDebt = farmer.getTotalDebt(settings.pricePerHectare);
                  final totalPaid = farmer.getTotalPaid();
                  final remaining = totalDebt - totalPaid;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FarmerDetailScreen(farmerId: farmer.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: remaining > 0 
                                    ? const Color(0xFFFFE0B2) 
                                    : const Color(0xFFC8E6C9),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Icon(
                                remaining > 0 ? Icons.pending_actions : Icons.check_circle,
                                color: remaining > 0 
                                    ? const Color(0xFFFF6F00) 
                                    : const Color(0xFF66BB6A),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farmer.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'مساحت: ${farmer.getTotalHectaresFormatted()} هکتار',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'باقیمانده: ${numberFormat.format(remaining)} تومان',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: remaining > 0 
                                          ? const Color(0xFFFF6F00) 
                                          : const Color(0xFF66BB6A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_left, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFarmerScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('افزودن کشاورز'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
