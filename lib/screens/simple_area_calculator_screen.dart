import 'package:flutter/material.dart';
import 'dart:math' as math;

class SimpleAreaCalculatorScreen extends StatefulWidget {
  const SimpleAreaCalculatorScreen({super.key});

  @override
  State<SimpleAreaCalculatorScreen> createState() =>
      _SimpleAreaCalculatorScreenState();
}

class _SimpleAreaCalculatorScreenState
    extends State<SimpleAreaCalculatorScreen> {
  final List<MapEntry<double, double>> _points = [];
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  double _calculatedArea = 0;

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _addPoint() {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا مختصات معتبر وارد کنید')),
      );
      return;
    }

    setState(() {
      _points.add(MapEntry(lat, lon));
      _latController.clear();
      _lonController.clear();

      if (_points.length >= 3) {
        _calculatedArea = _calculateArea();
      }
    });
  }

  void _removePoint(int index) {
    setState(() {
      _points.removeAt(index);
      if (_points.length >= 3) {
        _calculatedArea = _calculateArea();
      } else {
        _calculatedArea = 0;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _points.clear();
      _calculatedArea = 0;
    });
  }

  double _calculateArea() {
    if (_points.length < 3) return 0;

    double area = 0;
    int j = _points.length - 1;

    for (int i = 0; i < _points.length; i++) {
      area += (_points[j].value + _points[i].value) *
          (_points[j].key - _points[i].key);
      j = i;
    }

    area = area.abs() / 2.0;

    // Convert to hectares
    double avgLat =
        _points.map((p) => p.key).reduce((a, b) => a + b) / _points.length;
    double latToKm = 111.0;
    double lonToKm = 111.0 * math.cos(avgLat * math.pi / 180);

    double areaKm2 = area * latToKm * lonToKm;
    return areaKm2 * 100; // Convert to hectares
  }

  void _confirmArea() {
    if (_calculatedArea > 0) {
      Navigator.pop(context, _calculatedArea);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محاسبه مساحت'),
        actions: [
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearAll,
              tooltip: 'پاک کردن همه',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF66BB6A)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'نقاط GPS مرزی زمین را وارد کنید',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'می‌توانید از Google Maps یا GPS موبایل خود برای دریافت مختصات استفاده کنید',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'عرض جغرافیایی (Latitude)',
                      hintText: '35.6892',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lonController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'طول جغرافیایی (Longitude)',
                      hintText: '51.3890',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Add Point Button
            ElevatedButton.icon(
              onPressed: _addPoint,
              icon: const Icon(Icons.add_location),
              label: const Text('افزودن نقطه'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),

            // Points List
            if (_points.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نقاط ثبت شده (${_points.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_calculatedArea > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_calculatedArea.toStringAsFixed(2)} هکتار',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ..._points.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF66BB6A),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      'Lat: ${point.key.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      'Lon: ${point.value.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removePoint(index),
                    ),
                  ),
                );
              }),
            ],

            // Confirm Button
            if (_calculatedArea > 0) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _confirmArea,
                icon: const Icon(Icons.check),
                label: const Text('تایید و استفاده از این مساحت'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF66BB6A),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
