import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';

class MapLandPickerScreen extends StatefulWidget {
  const MapLandPickerScreen({super.key});

  @override
  State<MapLandPickerScreen> createState() => _MapLandPickerScreenState();
}

class _MapLandPickerScreenState extends State<MapLandPickerScreen> {
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();
  final List<LatLng> _polygonPoints = [];
  double _calculatedArea = 0;
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  bool _isSatelliteView = true; // Default to satellite
  int? _draggingPointIndex; // Index of point being dragged
  int? _selectedPointIndex; // Index of selected point for moving

  // Default location (Tehran, Iran)
  static const LatLng _initialPosition = LatLng(35.6892, 51.3890);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialLocation();
    });
  }

  Future<void> _loadInitialLocation() async {
    // Try to load last saved location
    final settings = DatabaseService.getSettings();
    if (settings.lastLatitude != null && settings.lastLongitude != null) {
      final savedLocation =
          LatLng(settings.lastLatitude!, settings.lastLongitude!);
      setState(() {
        _userLocation = savedLocation;
      });
      // Move map to saved location
      _mapController.move(savedLocation, 17.0);
    } else {
      // Get current location if no saved location
      await _getUserLocation();
    }
  }

  Future<void> _saveUserLocation(LatLng location) async {
    final settings = DatabaseService.getSettings();
    settings.lastLatitude = location.latitude;
    settings.lastLongitude = location.longitude;
    await DatabaseService.updateSettings(settings);
  }

  void _toggleMapType() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
    });
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('دسترسی به موقعیت مکانی رد شد')),
            );
          }
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('لطفاً دسترسی موقعیت مکانی را در تنظیمات فعال کنید')),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = newLocation;
        _isLoadingLocation = false;
      });

      // Save location to settings
      await _saveUserLocation(newLocation);

      // Move map to user location
      _mapController.move(_userLocation!, 17.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت موقعیت: $e')),
        );
      }
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    // Don't add new point if dragging
    if (_draggingPointIndex != null) return;

    setState(() {
      // If a point is selected, move it to new position
      if (_selectedPointIndex != null) {
        _polygonPoints[_selectedPointIndex!] = position;
        _selectedPointIndex = null; // Deselect after moving

        // Recalculate area
        if (_polygonPoints.length >= 3) {
          _calculatedArea = _calculatePolygonArea(_polygonPoints);
        }
      } else {
        // Add new point
        _polygonPoints.add(position);

        // Calculate area if we have at least 3 points
        if (_polygonPoints.length >= 3) {
          _calculatedArea = _calculatePolygonArea(_polygonPoints);
        }
      }
    });
  }

  void _onPointTapped(int index) {
    setState(() {
      // Toggle selection
      if (_selectedPointIndex == index) {
        _selectedPointIndex = null; // Deselect if already selected
      } else {
        _selectedPointIndex = index; // Select this point
      }
    });
  }

  void _onPointDragStart(int index) {
    setState(() {
      _draggingPointIndex = index;
    });
  }

  void _onPointDragUpdate(int index, LatLng newPosition) {
    setState(() {
      _polygonPoints[index] = newPosition;

      // Recalculate area
      if (_polygonPoints.length >= 3) {
        _calculatedArea = _calculatePolygonArea(_polygonPoints);
      }
    });
  }

  void _onPointDragEnd() {
    setState(() {
      _draggingPointIndex = null;
    });
  }

  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0;

    // Using Shoelace formula for polygon area
    double area = 0;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      area += (points[j].longitude + points[i].longitude) *
          (points[j].latitude - points[i].latitude);
      j = i;
    }

    area = area.abs() / 2.0;

    // Convert to hectares (approximate)
    double avgLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double latToKm = 111.0;
    double lonToKm = 111.0 * math.cos(avgLat * math.pi / 180);

    // Area in square kilometers
    double areaKm2 = area * latToKm * lonToKm;

    // Convert to hectares (1 km² = 100 hectares)
    return areaKm2 * 100;
  }

  void _clearPoints() {
    setState(() {
      _polygonPoints.clear();
      _calculatedArea = 0;
    });
  }

  void _undoLastPoint() {
    if (_polygonPoints.isEmpty) return;

    setState(() {
      _polygonPoints.removeLast();

      // Update area
      if (_polygonPoints.length >= 3) {
        _calculatedArea = _calculatePolygonArea(_polygonPoints);
      } else {
        _calculatedArea = 0;
      }
    });
  }

  Future<void> _confirmArea() async {
    if (_calculatedArea > 0) {
      // Take screenshot
      try {
        RenderRepaintBoundary boundary =
            _mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          Uint8List pngBytes = byteData.buffer.asUint8List();

          // Save to temporary directory
          final directory = await getTemporaryDirectory();
          final imagePath =
              '${directory.path}/land_${DateTime.now().millisecondsSinceEpoch}.png';
          final imageFile = File(imagePath);
          await imageFile.writeAsBytes(pngBytes);

          // Return both area and image path
          if (mounted) {
            Navigator.pop(context, {
              'area': _calculatedArea,
              'imagePath': imagePath,
            });
          }
        }
      } catch (e) {
        // If screenshot fails, just return the area
        if (mounted) {
          Navigator.pop(context, {'area': _calculatedArea});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب زمین روی نقشه'),
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _mapKey,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 15.0,
                onTap: _onMapTapped,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Map tiles based on view type
                if (_isSatelliteView) ...[
                  // Satellite imagery - trying multiple sources
                  TileLayer(
                    urlTemplate:
                        'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                    userAgentPackageName: 'com.example.tractor_finance_manage',
                    fallbackUrl:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  ),
                ] else
                  // Standard map
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.tractor_finance_manage',
                  ),
                // Polygon layer
                if (_polygonPoints.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _polygonPoints,
                        color: const Color(0xFF66BB6A).withOpacity(0.3),
                        borderColor: const Color(0xFF66BB6A),
                        borderStrokeWidth: 3,
                        isFilled: true,
                      ),
                    ],
                  ),
                // Markers layer
                MarkerLayer(
                  markers: [
                    // User location marker
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 3),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    // Polygon point markers (draggable)
                    ..._polygonPoints.asMap().entries.map((entry) {
                      final index = entry.key;
                      final point = entry.value;
                      final isDragging = _draggingPointIndex == index;
                      final isSelected = _selectedPointIndex == index;

                      return Marker(
                        point: point,
                        width: (isDragging || isSelected) ? 24 : 16,
                        height: (isDragging || isSelected) ? 24 : 16,
                        child: GestureDetector(
                          onTap: () => _onPointTapped(index),
                          onLongPressStart: (_) => _onPointDragStart(index),
                          onLongPressMoveUpdate: (details) {
                            // Convert screen position to map coordinates
                            final RenderBox? renderBox =
                                context.findRenderObject() as RenderBox?;
                            if (renderBox != null) {
                              final localPosition = renderBox
                                  .globalToLocal(details.globalPosition);
                              final mapSize = renderBox.size;

                              // Get map bounds
                              final bounds =
                                  _mapController.camera.visibleBounds;
                              final latDiff = bounds.north - bounds.south;
                              final lngDiff = bounds.east - bounds.west;

                              // Calculate new position
                              final newLat = bounds.north -
                                  (localPosition.dy / mapSize.height) * latDiff;
                              final newLng = bounds.west +
                                  (localPosition.dx / mapSize.width) * lngDiff;

                              _onPointDragUpdate(index, LatLng(newLat, newLng));
                            }
                          },
                          onLongPressEnd: (_) => _onPointDragEnd(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDragging
                                  ? Colors.orange
                                  : isSelected
                                      ? Colors.blue
                                      : const Color(0xFF66BB6A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: (isDragging || isSelected) ? 3 : 2,
                              ),
                              boxShadow: (isDragging || isSelected)
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Info card at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF66BB6A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedPointIndex != null
                                ? 'روی نقشه کلیک کنید تا نقطه انتخاب شده جابجا شود'
                                : 'روی نقشه کلیک کنید تا نقاط زمین را مشخص کنید',
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedPointIndex != null
                                  ? Colors.blue
                                  : Colors.black87,
                              fontWeight: _selectedPointIndex != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedPointIndex != null) ...[
                      const SizedBox(height: 4),
                      const Text(
                        '💡 برای لغو، دوباره روی نقطه کلیک کنید',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ],
                    if (_polygonPoints.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'تعداد نقاط: ${_polygonPoints.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                    if (_calculatedArea > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'مساحت: ${_calculatedArea.toStringAsFixed(2)} هکتار',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF66BB6A),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Undo button (top)
          if (_polygonPoints.isNotEmpty)
            Positioned(
              bottom: _calculatedArea > 0 ? 240 : 180,
              right: 16,
              child: FloatingActionButton(
                onPressed: _undoLastPoint,
                backgroundColor: Colors.white,
                heroTag: 'undo',
                tooltip: 'حذف آخرین نقطه',
                child: const Icon(
                  Icons.undo,
                  color: Colors.orange,
                ),
              ),
            ),

          // Clear all button
          if (_polygonPoints.isNotEmpty)
            Positioned(
              bottom: _calculatedArea > 0 ? 170 : 110,
              right: 16,
              child: FloatingActionButton(
                onPressed: _clearPoints,
                backgroundColor: Colors.white,
                heroTag: 'clear',
                tooltip: 'پاک کردن همه',
                child: const Icon(
                  Icons.clear,
                  color: Colors.red,
                ),
              ),
            ),

          // Map Type Toggle button
          Positioned(
            bottom: _calculatedArea > 0 ? 100 : 40,
            right: 16,
            child: FloatingActionButton(
              onPressed: _toggleMapType,
              backgroundColor: Colors.white,
              heroTag: 'mapType',
              child: Icon(
                _isSatelliteView ? Icons.map : Icons.satellite,
                color: const Color(0xFF66BB6A),
              ),
            ),
          ),

          // My Location button
          Positioned(
            bottom: _calculatedArea > 0 ? 30 : 40,
            left: 16,
            child: FloatingActionButton(
              onPressed: _isLoadingLocation ? null : _getUserLocation,
              backgroundColor: Colors.white,
              heroTag: 'myLocation',
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF66BB6A)),
            ),
          ),

          // Confirm button at bottom
          if (_calculatedArea > 0)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _confirmArea,
                icon: const Icon(Icons.check),
                label: const Text('تایید و استفاده از این مساحت'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
