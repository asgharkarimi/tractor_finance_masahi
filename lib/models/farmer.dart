import 'package:hive/hive.dart';
import 'land.dart';
import 'payment.dart';

part 'farmer.g.dart';

@HiveType(typeId: 2)
class Farmer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<Land> lands;

  @HiveField(3)
  List<Payment> payments;

  Farmer({
    required this.id,
    required this.name,
    List<Land>? lands,
    List<Payment>? payments,
  })  : lands = lands ?? [],
        payments = payments ?? [];

  double getTotalHectares() {
    return lands.fold(0.0, (sum, land) => sum + land.hectares);
  }

  String getTotalHectaresFormatted() {
    final total = getTotalHectares();
    // Round to 2 decimal places and remove trailing zeros
    if (total == total.toInt()) {
      return total.toInt().toString();
    }
    return total.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  double getTotalDebt(double pricePerHectare) {
    return lands.fold(0, (sum, land) => sum + land.calculateCost(pricePerHectare));
  }

  double getTotalPaid() {
    return payments.fold(0, (sum, payment) => sum + payment.amount);
  }

  double getRemainingDebt(double pricePerHectare) {
    return getTotalDebt(pricePerHectare) - getTotalPaid();
  }
}
