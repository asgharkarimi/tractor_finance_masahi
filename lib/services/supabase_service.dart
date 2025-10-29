import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farmer.dart';
import '../models/land.dart';
import '../models/payment.dart';
import 'database_service.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://lljsleoqzrxscnzzlynq.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsanNsZW9xenJ4c2NuenpseW5xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3Njk0MjAsImV4cCI6MjA3NzM0NTQyMH0.SK98VbJ1cXjbyxvLdBwYqbNM1GVOg4fbUXqkTRcimGo';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
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
        final landData = {
          'id': land.id,
          'farmer_id': farmer.id,
          'hectares': land.hectares,
          'name': land.name,
          'description': land.description,
          'image_path': land.imagePath,
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

  // Load all data from Supabase
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
}
