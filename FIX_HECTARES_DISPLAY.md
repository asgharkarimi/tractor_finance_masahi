# رفع مشکل نمایش مساحت

## مشکل
مساحت کل به صورت اعشار خیلی طولانی نمایش داده می‌شد:
- مثال: `3.900000000000004 هکتار`

## راه حل
متد جدید `getTotalHectaresFormatted()` به کلاس `Farmer` اضافه شد که:
- اگر عدد صحیح باشد، بدون اعشار نمایش می‌دهد (مثال: `3 هکتار`)
- اگر اعشار داشته باشد، فقط تا 2 رقم اعشار نمایش می‌دهد (مثال: `3.5 هکتار`)
- صفرهای اضافی در انتها را حذف می‌کند

## تغییرات اعمال شده

### 1. مدل Farmer (lib/models/farmer.dart)
```dart
String getTotalHectaresFormatted() {
  final total = getTotalHectares();
  // Round to 2 decimal places and remove trailing zeros
  if (total == total.toInt()) {
    return total.toInt().toString();
  }
  return total.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}
```

### 2. صفحات آپدیت شده
- `lib/screens/home_screen.dart` - صفحه اصلی
- `lib/screens/farmer_detail_screen.dart` - صفحه جزئیات کشاورز
- `lib/screens/report_screen.dart` - صفحه گزارش
- `lib/services/pdf_service.dart` - سرویس PDF

## نکته مهم
بعد از این تغییرات، حتماً باید:
1. Build runner را اجرا کنید: `flutter pub run build_runner build --delete-conflicting-outputs`
2. اپلیکیشن را کاملاً restart کنید (نه فقط hot reload)

## نتیجه
حالا مساحت در تمام صفحات به صورت تمیز و خوانا نمایش داده می‌شود.
