import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/farmer.dart';
import '../models/land.dart';
import 'map_land_picker_screen.dart';

class AddLandScreen extends StatefulWidget {
  final Farmer farmer;

  const AddLandScreen({super.key, required this.farmer});

  @override
  State<AddLandScreen> createState() => _AddLandScreenState();
}

class _AddLandScreenState extends State<AddLandScreen> {
  final _nameController = TextEditingController();
  final _hectaresController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _hectaresController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در انتخاب تصویر: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در گرفتن عکس: $e')),
        );
      }
    }
  }

  Future<void> _pickFromMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const MapLandPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        // Set area
        final area = result['area'] as double?;
        if (area != null) {
          _hectaresController.text = area.toStringAsFixed(2);
        }
        
        // Set screenshot as image
        final imagePath = result['imagePath'] as String?;
        if (imagePath != null) {
          _imagePath = imagePath;
        }
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF66BB6A)),
              title: const Text('انتخاب از گالری'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF66BB6A)),
              title: const Text('گرفتن عکس'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف عکس'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLand() async {
    if (_hectaresController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا مساحت زمین را وارد کنید')),
      );
      return;
    }

    final hectares = double.tryParse(_hectaresController.text);
    if (hectares == null || hectares <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا مساحت معتبر وارد کنید')),
      );
      return;
    }

    final land = Land(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      hectares: hectares,
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      imagePath: _imagePath,
    );

    widget.farmer.lands.add(land);
    await widget.farmer.save();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('افزودن زمین جدید'),
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
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF66BB6A)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'افزودن زمین جدید برای ${widget.farmer.name}',
                        style: const TextStyle(
                          color: Color(0xFF424242),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'نام زمین (اختیاری)',
                hintText: 'مثال: زمین شمالی، قطعه اول',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Hectares Field with Map Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hectaresController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'مساحت (هکتار)',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.calculate, color: Colors.white),
                    onPressed: _pickFromMap,
                    tooltip: 'محاسبه مساحت',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description Field
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'توضیحات اضافی (اختیاری)',
                hintText: 'مثال: نزدیک جاده اصلی',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 16),

            // Image Section
            if (_imagePath != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_imagePath!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _showImageOptions,
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _showImageOptions,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('افزودن عکس زمین'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF66BB6A),
                  side: const BorderSide(color: Color(0xFF66BB6A)),
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            const SizedBox(height: 32),

            // Save Button
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: _saveLand,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('ذخیره زمین', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
