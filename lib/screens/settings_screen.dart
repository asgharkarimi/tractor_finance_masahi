import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/settings.dart';
import '../services/database_service.dart';
import '../utils/number_formatter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _priceController;
  final numberFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    final settings = DatabaseService.getSettings();
    _priceController = TextEditingController(
      text: numberFormat.format(settings.pricePerHectare.toInt()),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final price = double.tryParse(_priceController.text.replaceAll(',', ''));
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا مبلغ معتبر وارد کنید')),
      );
      return;
    }

    final settings = Settings(pricePerHectare: price);
    await DatabaseService.updateSettings(settings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تنظیمات ذخیره شد')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تنظیمات'),
        ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'قیمت کشت هر هکتار',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'مبلغ (تومان)',
                hintText: '1,300,000',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('ذخیره', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
