import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 3)
class Settings extends HiveObject {
  @HiveField(0)
  double pricePerHectare;

  Settings({
    this.pricePerHectare = 1300000,
  });
}
