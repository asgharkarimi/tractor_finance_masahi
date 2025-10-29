import 'package:hive/hive.dart';

part 'land.g.dart';

@HiveType(typeId: 0)
class Land extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double hectares;

  @HiveField(2)
  String? name; // نام زمین

  @HiveField(3)
  String? imagePath;

  @HiveField(4)
  String? description; // توضیحات اضافی

  Land({
    required this.id,
    required this.hectares,
    this.name,
    this.imagePath,
    this.description,
  });

  double calculateCost(double pricePerHectare) {
    return hectares * pricePerHectare;
  }

  String get displayName => name ?? 'زمین ${hectares} هکتاری';
}
