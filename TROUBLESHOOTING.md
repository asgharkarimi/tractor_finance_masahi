# 🔧 راهنمای رفع مشکلات

## مشکل: خطای MaterialLocalizations

### علت:
پکیج `flutter_localizations` اضافه نشده بود.

### راه‌حل:
این مشکل برطرف شده است. اگر دوباره با این خطا مواجه شدید:

```bash
flutter clean
flutter pub get
flutter run
```

## مشکل: صفحه سفید هنگام اجرا

### علت‌های احتمالی:
1. فونت Vazir نصب نشده
2. خطا در initialization دیتابیس
3. مشکل در پکیج‌ها

### راه‌حل:

#### 1. استفاده بدون فونت (پیشنهادی)
نرم‌افزار اکنون با فونت پیش‌فرض سیستم کار می‌کند. فقط:

```bash
flutter clean
flutter pub get
flutter run
```

#### 2. نصب فونت Vazir (اختیاری)
اگر می‌خواهید فونت فارسی داشته باشید:

1. فونت را از [این لینک](https://github.com/rastikerdar/vazir-font/releases) دانلود کنید
2. فایل `Vazir.ttf` را در `assets/fonts/` قرار دهید
3. در `pubspec.yaml` خط‌های فونت را uncomment کنید:
```yaml
fonts:
  - family: Vazir
    fonts:
      - asset: assets/fonts/Vazir.ttf
```
4. در `lib/theme/app_theme.dart` خط `fontFamily: 'Vazir'` را uncomment کنید
5. اجرا کنید:
```bash
flutter pub get
flutter run
```

## مشکل: خطای "Failed to load asset"

### راه‌حل:
```bash
flutter clean
flutter pub get
flutter run
```

## مشکل: خطای Build Runner

### راه‌حل:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## مشکل: خطای دسترسی به دوربین/گالری

### Android:
1. در `android/app/src/main/AndroidManifest.xml` مجوزها را چک کنید
2. در تنظیمات گوشی دسترسی‌ها را بدهید

### iOS:
1. در `ios/Runner/Info.plist` توضیحات مجوزها را چک کنید
2. در تنظیمات گوشی دسترسی‌ها را بدهید

## مشکل: نرم‌افزار کند است

### راه‌حل:
1. نسخه Release بسازید:
```bash
flutter build apk --release
```

2. از نسخه Debug استفاده نکنید برای استفاده روزمره

## مشکل: عکس‌ها نمایش داده نمی‌شوند

### علت‌های احتمالی:
1. عکس از حافظه حذف شده
2. مسیر عکس اشتباه است

### راه‌حل:
1. عکس را دوباره آپلود کنید
2. از دوربین عکس جدید بگیرید

## مشکل: PDF ساخته نمی‌شود

### راه‌حل:
1. مطمئن شوید حداقل یک کشاورز ثبت شده
2. دسترسی ذخیره فایل را بدهید
3. فضای کافی در حافظه داشته باشید

## مشکل: دیتا پاک شد

### توضیح:
دیتا در دیتابیس Hive محلی ذخیره می‌شود. اگر:
- نرم‌افزار را uninstall کنید
- Cache را پاک کنید
- Data را clear کنید

دیتا پاک می‌شود.

### پیشگیری:
- گزارش PDF ماهانه بگیرید
- از نرم‌افزار backup استفاده کنید

## دستورات مفید برای رفع مشکل

### پاک کردن کامل و شروع مجدد:
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### مشاهده لاگ‌ها:
```bash
flutter run -v
```

### چک کردن دستگاه‌ها:
```bash
flutter devices
```

### چک کردن وضعیت Flutter:
```bash
flutter doctor -v
```

## نیاز به کمک بیشتر؟

1. لاگ خطا را کپی کنید
2. نسخه Flutter را چک کنید: `flutter --version`
3. مشکل را با جزئیات شرح دهید

## نکات مهم

✅ همیشه از نسخه Release برای استفاده واقعی استفاده کنید
✅ گزارش‌های PDF را ذخیره کنید
✅ قبل از uninstall از دیتا backup بگیرید
✅ دسترسی‌های لازم را بدهید
✅ فضای کافی در حافظه داشته باشید

---

**نکته**: نرم‌افزار اکنون بدون فونت Vazir هم کار می‌کند و از فونت پیش‌فرض سیستم استفاده می‌کند.
