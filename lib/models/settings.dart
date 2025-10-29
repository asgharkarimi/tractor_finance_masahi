import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 3)
class Settings extends HiveObject {
  @HiveField(0)
  double pricePerHectare;

  @HiveField(1)
  double? lastLatitude;

  @HiveField(2)
  double? lastLongitude;

  Settings({
    this.pricePerHectare = 1300000,
    this.lastLatitude,
    this.lastLongitude,
  });
}
