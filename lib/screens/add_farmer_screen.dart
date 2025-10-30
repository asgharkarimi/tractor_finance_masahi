import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/farmer.dart';
import '../models/land.dart';
import '../services/database_service.dart';
import 'map_land_picker_screen.dart';

class AddFarmerScreen extends StatefulWidget {
  final Farmer? farmer;

  const AddFarmerScreen({super.key, this.farmer});

  @override
  State<AddFarmerScreen> createState() => _AddFarmerScreenState();
}

class _AddFarmerScreenState extends State<AddFarmerScreen> {
  late TextEditingController _nameController;
  final List<LandInput> _lands = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.farmer?.name ?? '');
    
    if (widget.farmer != null) {
      for (var land in widget.farmer!.lands) {
        _lands.add(LandInput(
          nameController: TextEditingController(text: land.name ?? ''),
          hectaresController: TextEditingController(text: land.hectares.toString()),
          descriptionController: TextEditingController(text: land.description ?? ''),
          imagePath: land.imagePath,
        ));
      }
    }
    
    if (_lands.isEmpty) {
      _addLand();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var land in _lands) {
      land.nameController.dispose();
      land.hectaresController.dispose();
      land.descriptionController.dispose();
    }
    super.dispose();
  }

  void _addLand() {
    setState(() {
      _lands.add(LandInput(
        nameController: TextEditingController(),
        hectaresController: TextEditingController(),
        descriptionController: TextEditingController(),
        imagePath: null,
      ));
    });
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _lands[index].imagePath = image.path;
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

  Future<void> _takePhoto(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _lands[index].imagePath = image.path;
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

  Future<void> _pickFromMapForLand(int index) async {
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
          _lands[index].hectaresController.text = area.toStringAsFixed(2);
        }
        
        // Set screenshot as image
        final imagePath = result['imagePath'] as String?;
        if (imagePath != null) {
          _lands[index].imagePath = imagePath;
        }
      });
    }
  }

  void _showImageOptions(int index) {
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
                _pickImage(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF66BB6A)),
              title: const Text('گرفتن عکس'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(index);
              },
            ),
            if (_lands[index].imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف عکس'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _lands[index].imagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _removeLand(int index) {
    setState(() {
      _lands[index].nameController.dispose();
      _lands[index].hectaresController.dispose();
      _lands[index].descriptionController.dispose();
      _lands.removeAt(index);
    });
  }

  Future<void> _saveFarmer() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا نام کشاورز را وارد کنید')),
      );
      return;
    }

    final lands = <Land>[];
    for (var landInput in _lands) {
      final hectares = double.tryParse(landInput.hectaresController.text);
      if (hectares == null || hectares <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفا مساحت معتبر وارد کنید')),
        );
        return;
      }
      lands.add(Land(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hectares: hectares,
        name: landInput.nameController.text.trim().isEmpty
            ? null
            : landInput.nameController.text.trim(),
        description: landInput.descriptionController.text.trim().isEmpty
            ? null
            : landInput.descriptionController.text.trim(),
        imagePath: landInput.imagePath,
      ));
    }

    final farmer = Farmer(
      id: widget.farmer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      lands: lands,
      payments: widget.farmer?.payments ?? [],
    );

    // Save context before closing
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isEdit = widget.farmer != null;
    
    // Close screen immediately
    if (mounted) {
      Navigator.pop(context);
    }

    // Save in background
    try {
      await DatabaseService.addFarmer(farmer);
      
      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'کشاورز با موفقیت ویرایش شد' : 'کشاورز با موفقیت ذخیره شد'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
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
          title: Text(widget.farmer == null ? 'افزودن کشاورز' : 'ویرایش کشاورز'),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'نام کشاورز',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'زمین‌ها',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addLand,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._lands.asMap().entries.map((entry) {
              final index = entry.key;
              final land = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'زمین ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF66BB6A),
                            ),
                          ),
                          if (_lands.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeLand(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: land.nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'نام زمین (اختیاری)',
                          hintText: 'مثال: زمین شمالی، قطعه اول',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Hectares Field with Map Button
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: land.hectaresController,
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
                              icon: const Icon(Icons.map, color: Colors.white),
                              onPressed: () => _pickFromMapForLand(index),
                              tooltip: 'انتخاب از نقشه',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: land.descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'توضیحات اضافی (اختیاری)',
                          hintText: 'مثال: نزدیک جاده اصلی',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Image section
                      if (land.imagePath != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(land.imagePath!),
                                height: 150,
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
                                  onPressed: () => _showImageOptions(index),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _showImageOptions(index),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('افزودن عکس زمین'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF66BB6A),
                            side: const BorderSide(color: Color(0xFF66BB6A)),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: _saveFarmer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('ذخیره', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class LandInput {
  final TextEditingController nameController;
  final TextEditingController hectaresController;
  final TextEditingController descriptionController;
  String? imagePath;

  LandInput({
    required this.nameController,
    required this.hectaresController,
    required this.descriptionController,
    this.imagePath,
  });
}
