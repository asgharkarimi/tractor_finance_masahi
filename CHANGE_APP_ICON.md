# تغییر آیکون اپلیکیشن

## ✅ تنظیمات انجام شده

### 📦 پکیج اضافه شده:
- `flutter_launcher_icons: ^0.13.1`

### ⚙️ تنظیمات در pubspec.yaml:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_logo.png"
  adaptive_icon_background: "#66BB6A"
  adaptive_icon_foreground: "assets/images/app_logo.png"
```

## 🚀 مراحل اجرا:

### مرحله 1: نصب پکیج
```bash
flutter pub get
```

### مرحله 2: ساخت آیکون‌ها
```bash
flutter pub run flutter_launcher_icons
```

این دستور آیکون‌ها رو برای Android و iOS می‌سازه.

### مرحله 3: اجرای مجدد اپلیکیشن
```bash
flutter run
```

## 📱 نتیجه:

بعد از اجرای دستورات بالا:

### Android:
- ✅ آیکون اصلی: `app_logo.png`
- ✅ Adaptive Icon با پس‌زمینه سبز (#66BB6A)
- ✅ آیکون در تمام اندازه‌ها (mipmap)

### iOS:
- ✅ آیکون در تمام اندازه‌های مورد نیاز
- ✅ سازگار با iOS 14+

## 🎨 ویژگی‌های آیکون:

- **رنگ پس‌زمینه**: سبز (#66BB6A) - همرنگ با تم اپلیکیشن
- **لوگو**: app_logo.png از assets/images
- **Adaptive Icon**: برای Android 8.0+ با پس‌زمینه سبز

## 📝 نکات مهم:

1. **کیفیت تصویر**: مطمئن شو که `app_logo.png` حداقل 1024x1024 پیکسل باشه
2. **فرمت**: PNG با پس‌زمینه شفاف بهترین گزینه است
3. **Adaptive Icon**: در Android 8.0+ آیکون به صورت دایره یا مربع گرد نمایش داده میشه

## 🔍 بررسی نتیجه:

بعد از اجرا، آیکون جدید رو می‌تونی در این مکان‌ها ببینی:

### Android:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png`

### iOS:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## ⚠️ عیب‌یابی:

### آیکون تغییر نکرد:
1. اپلیکیشن رو کاملاً uninstall کن
2. دوباره نصب کن: `flutter run`
3. دستگاه رو restart کن

### خطا در ساخت آیکون:
1. مطمئن شو که `app_logo.png` در `assets/images/` وجود داره
2. سایز تصویر رو چک کن (حداقل 512x512)
3. دستور رو دوباره اجرا کن

## 🎯 دستور کامل (یکجا):

```bash
# نصب پکیج
flutter pub get

# ساخت آیکون‌ها
flutter pub run flutter_launcher_icons

# پاک کردن و rebuild
flutter clean
flutter pub get

# اجرا
flutter run
```

## ✨ نتیجه نهایی:

حالا اپلیکیشن با آیکون سفارشی `app_logo.png` و پس‌زمینه سبز در لانچر نمایش داده میشه! 🎉
