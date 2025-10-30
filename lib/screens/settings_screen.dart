import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/settings.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
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

    // Save context before closing
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Close screen immediately
    if (mounted) {
      Navigator.pop(context);
    }

    // Save in background
    try {
      final settings = Settings(pricePerHectare: price);
      await DatabaseService.updateSettings(settings);
      
      // Show success message
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تنظیمات با موفقیت ذخیره شد'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('خطا در ذخیره: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تنظیمات'),
        ),
      body: SingleChildScrollView(
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('ذخیره', style: TextStyle(fontSize: 16)),
              ),
            ),
            const Divider(height: 32),
            const Text(
              'همگام‌سازی با سرور',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _SyncSection(),
          ],
        ),
      ),
      ),
    );
  }
}

class _SyncSection extends StatefulWidget {
  @override
  State<_SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<_SyncSection> {
  bool _isSyncing = false;
  bool _isLoading = false;

  Future<void> _smartSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await SupabaseService.smartSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('همگام‌سازی هوشمند با موفقیت انجام شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در همگام‌سازی: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _syncToSupabase() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await SupabaseService.syncAllFarmers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ارسال به سرور با موفقیت انجام شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _loadFromSupabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بارگذاری از سرور'),
        content: const Text(
          'این عملیات تمام داده‌های محلی را با داده‌های سرور جایگزین می‌کند. آیا مطمئن هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('خیر'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('بله'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Clear local data
      final farmersBox = DatabaseService.getFarmersBox();
      await farmersBox.clear();

      // Load from Supabase
      await SupabaseService.loadAllFromSupabase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بارگذاری با موفقیت انجام شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: const Color(0xFFE8F5E9),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF66BB6A)),
                    SizedBox(width: 8),
                    Text(
                      'همگام‌سازی هوشمند',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• داده‌های محلی و سرور را با هم ترکیب می‌کند\n'
                  '• هیچ داده‌ای حذف نمی‌شود\n'
                  '• تمام زمین‌ها و پرداختی‌ها حفظ می‌شوند',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton.icon(
            onPressed: _isSyncing ? null : _smartSync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: const Text('همگام‌سازی هوشمند'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF66BB6A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: OutlinedButton.icon(
            onPressed: _isSyncing ? null : _syncToSupabase,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            label: const Text('ارسال به سرور (بازنویسی)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: const Color(0xFF66BB6A),
              side: const BorderSide(color: Color(0xFF66BB6A)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _loadFromSupabase,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download),
            label: const Text('دریافت از سرور (بازنویسی)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
      ],
    );
  }
}
