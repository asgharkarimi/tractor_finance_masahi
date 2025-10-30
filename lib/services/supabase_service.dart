import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/farmer.dart';
import '../models/land.dart';
import '../models/payment.dart';
import 'database_service.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://lljsleoqzrxscnzzlynq.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsanNsZW9xenJ4c2NuenpseW5xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3Njk0MjAsImV4cCI6MjA3NzM0NTQyMH0.SK98VbJ1cXjbyxvLdBwYqbNM1GVOg4fbUXqkTRcimGo';

  static SupabaseClient get client => Supabase.instance.client;
  static const String storageBucket = 'land-images';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Upload image to Supabase Storage
  static Future<String?> uploadImage(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        print('File does not exist: $localPath');
        return null;
      }

      // Generate unique filename
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(localPath)}';

      // Upload to Supabase Storage
      await client.storage.from(storageBucket).upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl =
          client.storage.from(storageBucket).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Download image from Supabase Storage
  static Future<String?> downloadImage(String imageUrl) async {
    try {
      // If it's not a URL, return as is (might be local path)
      if (!imageUrl.startsWith('http')) {
        return imageUrl;
      }

      // Extract filename from URL
      // URL format: https://.../storage/v1/object/public/land-images/filename.jpg
      final uri = Uri.parse(imageUrl);
      String fileName = uri.pathSegments.last;

      // If URL contains 'land-images', extract everything after it
      final pathString = uri.path;
      if (pathString.contains('land-images/')) {
        final parts = pathString.split('land-images/');
        if (parts.length > 1) {
          fileName = parts[1];
        }
      }

      // Check if already downloaded
      final directory = await getApplicationDocumentsDirectory();
      final localPath = path.join(directory.path, 'images', fileName);
      final file = File(localPath);

      if (await file.exists()) {
        return localPath; // Already downloaded
      }

      // Download from Supabase Storage
      final bytes = await client.storage.from(storageBucket).download(fileName);

      // Create directory if not exists
      final imageDir = Directory(path.join(directory.path, 'images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Write file
      await file.writeAsBytes(bytes);

      return localPath;
    } catch (e) {
      print('Error downloading image: $e');
      // Return original URL if download fails (will show broken image)
      return imageUrl;
    }
  }

  // Sync all farmers to Supabase
  static Future<void> syncAllFarmers() async {
    try {
      final farmers = DatabaseService.getFarmersBox().values.toList();

      for (var farmer in farmers) {
        await syncFarmer(farmer);
      }
    } catch (e) {
      print('Error syncing all farmers: $e');
      rethrow;
    }
  }

  // Sync single farmer to Supabase
  static Future<void> syncFarmer(Farmer farmer) async {
    try {
      // Check if farmer exists
      final existingFarmer = await client
          .from('farmers')
          .select()
          .eq('id', farmer.id)
          .maybeSingle();

      final farmerData = {
        'id': farmer.id,
        'name': farmer.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingFarmer == null) {
        // Insert new farmer
        await client.from('farmers').insert(farmerData);
      } else {
        // Update existing farmer
        await client.from('farmers').update(farmerData).eq('id', farmer.id);
      }

      // Sync lands
      await syncLands(farmer);

      // Sync payments
      await syncPayments(farmer);
    } catch (e) {
      print('Error syncing farmer ${farmer.id}: $e');
      rethrow;
    }
  }

  // Sync lands for a farmer
  static Future<void> syncLands(Farmer farmer) async {
    try {
      // Delete old lands for this farmer
      await client.from('lands').delete().eq('farmer_id', farmer.id);

      // Insert all current lands
      for (var land in farmer.lands) {
        String? imageUrl;

        // Upload image if exists
        if (land.imagePath != null && land.imagePath!.isNotEmpty) {
          // Check if it's a local path or already a URL
          if (!land.imagePath!.startsWith('http')) {
            imageUrl = await uploadImage(land.imagePath!);
          } else {
            imageUrl = land.imagePath; // Already a URL
          }
        }

        final landData = {
          'id': land.id,
          'farmer_id': farmer.id,
          'hectares': land.hectares,
          'name': land.name,
          'description': land.description,
          'image_path': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await client.from('lands').insert(landData);
      }
    } catch (e) {
      print('Error syncing lands for farmer ${farmer.id}: $e');
      rethrow;
    }
  }

  // Sync payments for a farmer
  static Future<void> syncPayments(Farmer farmer) async {
    try {
      // Delete old payments for this farmer
      await client.from('payments').delete().eq('farmer_id', farmer.id);

      // Insert all current payments
      for (var payment in farmer.payments) {
        final paymentData = {
          'id': payment.id,
          'farmer_id': farmer.id,
          'amount': payment.amount,
          'date': payment.date.toIso8601String(),
          'note': payment.note,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await client.from('payments').insert(paymentData);
      }
    } catch (e) {
      print('Error syncing payments for farmer ${farmer.id}: $e');
      rethrow;
    }
  }

  // Load only farmer names (fast initial load)
  static Future<void> loadFarmerNamesOnly() async {
    try {
      // Get only farmer names (no lands, no payments)
      final farmersData = await client.from('farmers').select('id, name');

      for (var farmerData in farmersData) {
        final farmer = Farmer(
          id: farmerData['id'] as String,
          name: farmerData['name'] as String,
          lands: [], // Empty for now
          payments: [], // Empty for now
        );

        // Save without triggering sync
        await DatabaseService.getFarmersBox().put(farmer.id, farmer);
      }
    } catch (e) {
      print('Error loading farmer names: $e');
      rethrow;
    }
  }

  // Load full details for all farmers (background)
  static Future<void> loadFullDetailsInBackground() async {
    try {
      final farmers = DatabaseService.getAllFarmers();

      for (var farmer in farmers) {
        // Skip if already has data
        if (farmer.lands.isNotEmpty || farmer.payments.isNotEmpty) continue;

        await _loadFarmerDetails(farmer.id);
      }
    } catch (e) {
      print('Error loading full details: $e');
    }
  }

  // Load details for a single farmer
  static Future<void> _loadFarmerDetails(String farmerId) async {
    try {
      // Get lands
      final landsData =
          await client.from('lands').select().eq('farmer_id', farmerId);

      final lands = <Land>[];
      for (var landData in landsData) {
        String? localImagePath;
        final imageUrl = landData['image_path'] as String?;

        // Download image if exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          localImagePath = await downloadImage(imageUrl);
        }

        lands.add(Land(
          id: landData['id'] as String,
          hectares: (landData['hectares'] as num).toDouble(),
          name: landData['name'] as String?,
          description: landData['description'] as String?,
          imagePath: localImagePath ?? imageUrl,
        ));
      }

      // Get payments
      final paymentsData =
          await client.from('payments').select().eq('farmer_id', farmerId);

      final payments = paymentsData.map((paymentData) {
        return Payment(
          id: paymentData['id'] as String,
          amount: (paymentData['amount'] as num).toDouble(),
          date: DateTime.parse(paymentData['date'] as String),
          note: paymentData['note'] as String?,
        );
      }).toList();

      // Update farmer with full data
      final farmer = DatabaseService.getFarmer(farmerId);
      if (farmer != null) {
        farmer.lands.addAll(lands);
        farmer.payments.addAll(payments);
        await DatabaseService.getFarmersBox().put(farmer.id, farmer);
      }
    } catch (e) {
      print('Error loading details for farmer $farmerId: $e');
    }
  }

  // Load all data from Supabase (full sync)
  static Future<void> loadAllFromSupabase() async {
    try {
      // Get all farmers
      final farmersData = await client.from('farmers').select();

      for (var farmerData in farmersData) {
        final farmerId = farmerData['id'] as String;

        // Get lands for this farmer
        final landsData =
            await client.from('lands').select().eq('farmer_id', farmerId);

        final lands = landsData.map((landData) {
          return Land(
            id: landData['id'] as String,
            hectares: (landData['hectares'] as num).toDouble(),
            name: landData['name'] as String?,
            description: landData['description'] as String?,
            imagePath: landData['image_path'] as String?,
          );
        }).toList();

        // Get payments for this farmer
        final paymentsData =
            await client.from('payments').select().eq('farmer_id', farmerId);

        final payments = paymentsData.map((paymentData) {
          return Payment(
            id: paymentData['id'] as String,
            amount: (paymentData['amount'] as num).toDouble(),
            date: DateTime.parse(paymentData['date'] as String),
            note: paymentData['note'] as String?,
          );
        }).toList();

        // Create farmer object
        final farmer = Farmer(
          id: farmerId,
          name: farmerData['name'] as String,
          lands: lands,
          payments: payments,
        );

        // Save to local database
        await DatabaseService.addFarmer(farmer);
      }
    } catch (e) {
      print('Error loading data from Supabase: $e');
      rethrow;
    }
  }

  // Delete farmer from Supabase
  static Future<void> deleteFarmer(String farmerId) async {
    try {
      // Delete payments
      await client.from('payments').delete().eq('farmer_id', farmerId);

      // Delete lands
      await client.from('lands').delete().eq('farmer_id', farmerId);

      // Delete farmer
      await client.from('farmers').delete().eq('id', farmerId);
    } catch (e) {
      print('Error deleting farmer from Supabase: $e');
      rethrow;
    }
  }

  // Check connection
  static Future<bool> checkConnection() async {
    try {
      await client.from('farmers').select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get count of farmers in server
  static Future<int> getServerFarmersCount() async {
    try {
      final response = await client.from('farmers').select('id');
      return response.length;
    } catch (e) {
      print('Error getting server farmers count: $e');
      return 0;
    }
  }

  // Smart sync: Merge local and server data
  static Future<void> smartSync() async {
    try {
      // Get all server farmers
      final farmersData = await client.from('farmers').select();
      final serverFarmerIds = <String>{};
      final Map<String, Map<String, dynamic>> serverFarmersMap = {};

      for (var farmerData in farmersData) {
        final farmerId = farmerData['id'] as String;
        serverFarmerIds.add(farmerId);
        serverFarmersMap[farmerId] = farmerData;
      }

      // Get all local farmers
      final localFarmers = DatabaseService.getAllFarmers();
      final localFarmerIds = localFarmers.map((f) => f.id).toSet();

      // Find farmers only in server (need to download)
      final onlyInServer = serverFarmerIds.difference(localFarmerIds);

      // Find farmers only in local (need to upload)
      final onlyInLocal = localFarmerIds.difference(serverFarmerIds);

      // Find farmers in both (need to merge)
      final inBoth = serverFarmerIds.intersection(localFarmerIds);

      // Download farmers only in server
      for (var farmerId in onlyInServer) {
        await _downloadFarmer(farmerId);
      }

      // Upload farmers only in local
      for (var farmerId in onlyInLocal) {
        final farmer = DatabaseService.getFarmer(farmerId);
        if (farmer != null) {
          await syncFarmer(farmer);
        }
      }

      // Merge farmers in both (use most recent data)
      for (var farmerId in inBoth) {
        await _mergeFarmer(farmerId);
      }
    } catch (e) {
      print('Error in smart sync: $e');
      rethrow;
    }
  }

  // Download a single farmer from server
  static Future<void> _downloadFarmer(String farmerId) async {
    try {
      final farmerData =
          await client.from('farmers').select().eq('id', farmerId).single();

      // Get lands
      final landsData =
          await client.from('lands').select().eq('farmer_id', farmerId);

      final lands = <Land>[];
      for (var landData in landsData) {
        String? localImagePath;
        final imageUrl = landData['image_path'] as String?;

        // Download image if exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          localImagePath = await downloadImage(imageUrl);
        }

        lands.add(Land(
          id: landData['id'] as String,
          hectares: (landData['hectares'] as num).toDouble(),
          name: landData['name'] as String?,
          description: landData['description'] as String?,
          imagePath: localImagePath ?? imageUrl,
        ));
      }

      // Get payments
      final paymentsData =
          await client.from('payments').select().eq('farmer_id', farmerId);

      final payments = paymentsData.map((paymentData) {
        return Payment(
          id: paymentData['id'] as String,
          amount: (paymentData['amount'] as num).toDouble(),
          date: DateTime.parse(paymentData['date'] as String),
          note: paymentData['note'] as String?,
        );
      }).toList();

      // Create and save farmer
      final farmer = Farmer(
        id: farmerId,
        name: farmerData['name'] as String,
        lands: lands,
        payments: payments,
      );

      // Save without triggering sync
      await DatabaseService.getFarmersBox().put(farmer.id, farmer);
    } catch (e) {
      print('Error downloading farmer $farmerId: $e');
      rethrow;
    }
  }

  // Merge farmer data (combine local and server)
  static Future<void> _mergeFarmer(String farmerId) async {
    try {
      final localFarmer = DatabaseService.getFarmer(farmerId);
      if (localFarmer == null) return;

      // Get server data (we only need lands and payments for merging)

      final serverLandsData =
          await client.from('lands').select().eq('farmer_id', farmerId);

      final serverPaymentsData =
          await client.from('payments').select().eq('farmer_id', farmerId);

      // Merge lands (combine unique lands from both)
      final Map<String, Land> landsMap = {};
      for (var land in localFarmer.lands) {
        landsMap[land.id] = land;
      }
      for (var landData in serverLandsData) {
        final landId = landData['id'] as String;
        if (!landsMap.containsKey(landId)) {
          String? localImagePath;
          final imageUrl = landData['image_path'] as String?;

          // Download image if exists
          if (imageUrl != null && imageUrl.isNotEmpty) {
            localImagePath = await downloadImage(imageUrl);
          }

          landsMap[landId] = Land(
            id: landId,
            hectares: (landData['hectares'] as num).toDouble(),
            name: landData['name'] as String?,
            description: landData['description'] as String?,
            imagePath: localImagePath ?? imageUrl,
          );
        }
      }

      // Merge payments (combine unique payments from both)
      final Map<String, Payment> paymentsMap = {};
      for (var payment in localFarmer.payments) {
        paymentsMap[payment.id] = payment;
      }
      for (var paymentData in serverPaymentsData) {
        final paymentId = paymentData['id'] as String;
        if (!paymentsMap.containsKey(paymentId)) {
          paymentsMap[paymentId] = Payment(
            id: paymentId,
            amount: (paymentData['amount'] as num).toDouble(),
            date: DateTime.parse(paymentData['date'] as String),
            note: paymentData['note'] as String?,
          );
        }
      }

      // Create merged farmer
      final mergedFarmer = Farmer(
        id: farmerId,
        name: localFarmer.name, // Keep local name
        lands: landsMap.values.toList(),
        payments: paymentsMap.values.toList(),
      );

      // Save merged data locally
      await DatabaseService.getFarmersBox().put(mergedFarmer.id, mergedFarmer);

      // Upload merged data to server
      await syncFarmer(mergedFarmer);
    } catch (e) {
      print('Error merging farmer $farmerId: $e');
      rethrow;
    }
  }
}
