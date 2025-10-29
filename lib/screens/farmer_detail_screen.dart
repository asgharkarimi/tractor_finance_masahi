import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/farmer.dart';
import '../models/land.dart';
import '../models/payment.dart';
import '../models/settings.dart';
import '../services/database_service.dart';
import '../utils/number_formatter.dart';
import 'add_farmer_screen.dart';
import 'add_land_screen.dart';
import 'image_viewer_screen.dart';

class FarmerDetailScreen extends StatelessWidget {
  final String farmerId;

  const FarmerDetailScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('yyyy/MM/dd');

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
        title: const Text('جزئیات کشاورز'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final farmer = DatabaseService.getFarmer(farmerId);
              if (farmer != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddFarmerScreen(farmer: farmer),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('حذف کشاورز'),
                  content: const Text('آیا مطمئن هستید؟'),
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

              if (confirm == true && context.mounted) {
                await DatabaseService.deleteFarmer(farmerId);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.getFarmersBox().listenable(),
        builder: (context, Box<Farmer> box, _) {
          final farmer = box.get(farmerId);

          if (farmer == null) {
            return const Center(child: Text('کشاورز یافت نشد'));
          }

          return ValueListenableBuilder(
            valueListenable: DatabaseService.getSettingsBox().listenable(),
            builder: (context, Box<Settings> settingsBox, _) {
              final settings = DatabaseService.getSettings();
              final totalDebt = farmer.getTotalDebt(settings.pricePerHectare);
              final totalPaid = farmer.getTotalPaid();
              final remaining = totalDebt - totalPaid;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card with Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Color(0xFF66BB6A),
                            Color(0xFF81C784),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF66BB6A).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  farmer.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.landscape,
                                  label: 'مساحت کل',
                                  value: farmer.getTotalHectaresFormatted(),
                                  unit: 'هکتار',
                                  iconColor: const Color(0xFF66BB6A),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.account_balance_wallet,
                                  label: 'بدهی',
                                  value: numberFormat.format(totalDebt),
                                  unit: 'تومان',
                                  isSmall: true,
                                  valueColor: Colors.red,
                                  iconColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.payments,
                                  label: 'پرداختی',
                                  value: numberFormat.format(totalPaid),
                                  unit: 'تومان',
                                  isSmall: true,
                                  valueColor: const Color(0xFF66BB6A),
                                  iconColor: const Color(0xFF66BB6A),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: remaining > 0
                                      ? Icons.warning
                                      : Icons.check_circle,
                                  label: 'باقیمانده',
                                  value: numberFormat.format(remaining),
                                  unit: 'تومان',
                                  isSmall: true,
                                  valueColor: remaining > 0
                                      ? Colors.orange
                                      : const Color(0xFF66BB6A),
                                  iconColor: remaining > 0
                                      ? Colors.orange
                                      : const Color(0xFF66BB6A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lands Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.terrain,
                                    color: Color(0xFF66BB6A),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'زمین‌ها',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Lands List
                            if (farmer.lands.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.landscape_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'زمینی ثبت نشده است',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...farmer.lands.asMap().entries.map((entry) {
                                final index = entry.key;
                                final land = entry.value;
                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: index < farmer.lands.length - 1
                                        ? 12
                                        : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (land.imagePath != null)
                                            Stack(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ImageViewerScreen(
                                                          imagePath:
                                                              land.imagePath!,
                                                          title: land.name ??
                                                              'عکس زمین',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                            top: Radius.circular(
                                                                12)),
                                                    child: Image.file(
                                                      File(land.imagePath!),
                                                      height: 180,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          height: 180,
                                                          color: Colors.grey[300],
                                                          child: const Center(
                                                            child: Icon(
                                                                Icons
                                                                    .broken_image,
                                                                size: 50,
                                                                color:
                                                                    Colors.grey),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                            if (land.name != null)
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment
                                                          .bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        Colors.black.withValues(
                                                            alpha: 0.7),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                  child: Text(
                                                    land.name!,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (land.name != null &&
                                                land.imagePath == null) ...[
                                              Row(
                                                children: [
                                                  const Icon(Icons.label,
                                                      size: 20,
                                                      color: Color(0xFF66BB6A)),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    land.name!,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF66BB6A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.straighten,
                                                        size: 18,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${land.hectares} هکتار',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFE8F5E9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    '${numberFormat.format(land.calculateCost(settings.pricePerHectare))} تومان',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF66BB6A),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (land.description != null) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(Icons.notes,
                                                        size: 16,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        land.description!,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Delete button
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () => _deleteLand(context, farmer, land),
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    
                    // Add Land Button (outside card)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddLandScreen(farmer: farmer),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('افزودن زمین جدید'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Payments Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: Color(0xFF66BB6A),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'پرداختی‌ها',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Payments List
                            if (farmer.payments.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'پرداختی ثبت نشده است',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...farmer.payments.asMap().entries.map((entry) {
                                final index = entry.key;
                                final payment = entry.value;
                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: index < farmer.payments.length - 1
                                        ? 12
                                        : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF66BB6A),
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      '${numberFormat.format(payment.amount)} تومان',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              dateFormat.format(payment.date),
                                              style: TextStyle(
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                        if (payment.note != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            payment.note!,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red[400],
                                      onPressed: () => _deletePayment(
                                          context, farmer, payment),
                                    ),
                                  ),
                                );
                              }),

                            // Add Payment Button
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showAddPaymentDialog(context, farmer),
                                icon: const Icon(Icons.add),
                                label: const Text('افزودن پرداخت'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF66BB6A),
                                  side: const BorderSide(
                                    color: Color(0xFF66BB6A),
                                    width: 1.5,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    bool isSmall = false,
    Color? valueColor,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF424242), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF424242),
              fontSize: isSmall ? 14 : 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, Farmer farmer) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن پرداخت'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'مبلغ (تومان)',
                hintText: '100,000',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'یادداشت (اختیاری)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.replaceAll(',', ''));
              if (amount == null || amount <= 0) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لطفا مبلغ معتبر وارد کنید')),
                  );
                }
                return;
              }

              final payment = Payment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                amount: amount,
                date: DateTime.now(),
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
              );

              farmer.payments.add(payment);
              await farmer.save();

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _deletePayment(
      BuildContext context, Farmer farmer, Payment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف پرداخت'),
        content: const Text('آیا مطمئن هستید؟'),
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

    if (confirm == true) {
      farmer.payments.remove(payment);
      await farmer.save();
    }
  }

  void _deleteLand(BuildContext context, Farmer farmer, Land land) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف زمین'),
        content: Text(
          land.name != null
              ? 'آیا از حذف "${land.name}" مطمئن هستید؟'
              : 'آیا از حذف این زمین مطمئن هستید؟',
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

    if (confirm == true) {
      farmer.lands.remove(land);
      await farmer.save();
    }
  }
}
