import 'package:hive_flutter/hive_flutter.dart';
import '../models/farmer.dart';
import '../models/land.dart';
import '../models/payment.dart';
import '../models/settings.dart';
import 'supabase_service.dart';

class DatabaseService {
  static const String farmersBox = 'farmers';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(LandAdapter());
    Hive.registerAdapter(PaymentAdapter());
    Hive.registerAdapter(FarmerAdapter());
    Hive.registerAdapter(SettingsAdapter());

    await Hive.openBox<Farmer>(farmersBox);
    await Hive.openBox<Settings>(settingsBox);

    // Initialize settings if not exists
    final settingsBoxInstance = Hive.box<Settings>(settingsBox);
    if (settingsBoxInstance.isEmpty) {
      await settingsBoxInstance.put('settings', Settings());
    }
  }

  static Box<Farmer> getFarmersBox() {
    return Hive.box<Farmer>(farmersBox);
  }

  static Box<Settings> getSettingsBox() {
    return Hive.box<Settings>(settingsBox);
  }

  static Settings getSettings() {
    return getSettingsBox().get('settings', defaultValue: Settings())!;
  }

  static Future<void> updateSettings(Settings settings) async {
    await getSettingsBox().put('settings', settings);
  }

  static Future<void> addFarmer(Farmer farmer) async {
    await getFarmersBox().put(farmer.id, farmer);
    // Sync to Supabase
    try {
      await SupabaseService.syncFarmer(farmer);
    } catch (e) {
      print('Failed to sync farmer to Supabase: $e');
    }
  }

  static Future<void> deleteFarmer(String id) async {
    await getFarmersBox().delete(id);
    // Delete from Supabase
    try {
      await SupabaseService.deleteFarmer(id);
    } catch (e) {
      print('Failed to delete farmer from Supabase: $e');
    }
  }

  static List<Farmer> getAllFarmers() {
    return getFarmersBox().values.toList();
  }

  static Farmer? getFarmer(String id) {
    return getFarmersBox().get(id);
  }
}
