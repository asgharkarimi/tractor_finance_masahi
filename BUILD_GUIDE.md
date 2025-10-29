# راهنمای ساخت و نصب

## ساخت APK برای اندروید

```bash
# ساخت APK نسخه Release
flutter build apk --release

# فایل APK در مسیر زیر ساخته می‌شود:
# build/app/outputs/flutter-apk/app-release.apk
```

## ساخت برای iOS

```bash
flutter build ios --release
```

## ساخت برای Windows

```bash
flutter build windows --release
```

## ساخت برای Web

```bash
flutter build web --release
```

## اجرای نرم‌افزار در حالت توسعه

```bash
# اجرا روی دستگاه متصل
flutter run

# اجرا با hot reload
flutter run --hot
```

## نکات مهم

- قبل از ساخت نسخه نهایی، حتما `flutter pub get` را اجرا کنید
- برای ساخت APK کوچکتر می‌توانید از دستور زیر استفاده کنید:
  ```bash
  flutter build apk --split-per-abi
  ```
- برای تست روی دستگاه واقعی، از دستور `flutter devices` لیست دستگاه‌ها را ببینید
