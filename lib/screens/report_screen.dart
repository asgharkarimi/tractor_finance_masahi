import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/farmer.dart';
import '../models/settings.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('گزارش درآمد'),
        ),
        body: ValueListenableBuilder(
          valueListenable: DatabaseService.getFarmersBox().listenable(),
          builder: (context, Box<Farmer> box, _) {
            final farmers = box.values.toList();

            return ValueListenableBuilder(
              valueListenable: DatabaseService.getSettingsBox().listenable(),
              builder: (context, Box<Settings> settingsBox, _) {
                final settings = DatabaseService.getSettings();

                double totalIncome = 0;
                double totalReceived = 0;
                double totalRemaining = 0;

                for (var farmer in farmers) {
                  final debt = farmer.getTotalDebt(settings.pricePerHectare);
                  final paid = farmer.getTotalPaid();
                  totalIncome += debt;
                  totalReceived += paid;
                  totalRemaining += (debt - paid);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary Card with Gradient
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
                              color: const Color(0xFF66BB6A)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
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
                                    Icons.assessment,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'خلاصه گزارش',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.account_balance_wallet,
                                    label: 'مجموع درآمد',
                                    value: numberFormat
                                        .format(totalIncome.toInt()),
                                    unit: 'تومان',
                                    iconColor: const Color(0xFF2196F3),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.check_circle,
                                    label: 'وصول شده',
                                    value: numberFormat
                                        .format(totalReceived.toInt()),
                                    unit: 'تومان',
                                    iconColor: const Color(0xFF66BB6A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildStatCard(
                              icon: totalRemaining > 0
                                  ? Icons.pending
                                  : Icons.done_all,
                              label: 'باقیمانده',
                              value:
                                  numberFormat.format(totalRemaining.toInt()),
                              unit: 'تومان',
                              iconColor: totalRemaining > 0
                                  ? Colors.orange
                                  : const Color(0xFF66BB6A),
                              isFullWidth: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // PDF Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: farmers.isEmpty
                              ? null
                              : () async {
                                  try {
                                    await PdfService.generateReport(
                                      farmers: farmers,
                                      pricePerHectare: settings.pricePerHectare,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('خطا در ایجاد PDF: $e')),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(Icons.picture_as_pdf, size: 24),
                          label: const Text('دریافت گزارش PDF',
                              style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                              Icons.people,
                              color: Color(0xFF66BB6A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'جزئیات کشاورزان',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (farmers.isEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'هیچ کشاورزی ثبت نشده است',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...farmers.map((farmer) {
                          final debt =
                              farmer.getTotalDebt(settings.pricePerHectare);
                          final paid = farmer.getTotalPaid();
                          final remaining = debt - paid;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF66BB6A),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          farmer.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: remaining > 0
                                              ? const Color(0xFFFFE0B2)
                                              : const Color(0xFFC8E6C9),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              remaining > 0
                                                  ? Icons.pending_actions
                                                  : Icons.check_circle,
                                              size: 16,
                                              color: remaining > 0
                                                  ? const Color(0xFFFF6F00)
                                                  : const Color(0xFF66BB6A),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              remaining > 0
                                                  ? 'بدهکار'
                                                  : 'تسویه',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: remaining > 0
                                                    ? const Color(0xFFFF6F00)
                                                    : const Color(0xFF66BB6A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildDetailRow(
                                          'مساحت کل',
                                          '${farmer.getTotalHectaresFormatted()} هکتار',
                                          icon: Icons.landscape,
                                        ),
                                        const Divider(height: 16),
                                        _buildDetailRow(
                                          'بدهی کل',
                                          '${numberFormat.format(debt.toInt())} تومان',
                                          icon: Icons.account_balance_wallet,
                                          valueColor: Colors.red,
                                        ),
                                        const Divider(height: 16),
                                        _buildDetailRow(
                                          'پرداختی',
                                          '${numberFormat.format(paid.toInt())} تومان',
                                          icon: Icons.payments,
                                          valueColor: Colors.green,
                                        ),
                                        const Divider(height: 16),
                                        _buildDetailRow(
                                          'باقیمانده',
                                          '${numberFormat.format(remaining.toInt())} تومان',
                                          icon: remaining > 0
                                              ? Icons.warning
                                              : Icons.check_circle,
                                          valueColor: remaining > 0
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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
    required Color iconColor,
    bool isFullWidth = false,
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
              Icon(icon, color: iconColor, size: 18),
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
            style: const TextStyle(
              color: Color(0xFF424242),
              fontSize: 16,
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

  Widget _buildDetailRow(String label, String value,
      {Color? valueColor, IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
