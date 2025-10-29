# دستورات تغییر آیکون اپلیکیشن

## 🚀 این دستورات رو به ترتیب در Terminal اجرا کن:

### مرحله 1: نصب پکیج‌ها
```bash
flutter pub get
```

### مرحله 2: ساخت آیکون‌ها
```bash
dart run flutter_launcher_icons
```

یا:
```bash
flutter pub run flutter_launcher_icons
```

### مرحله 3: پاک کردن و rebuild
```bash
flutter clean
flutter pub get
```

### مرحله 4: اجرای اپلیکیشن
```bash
flutter run
```

## ✅ بعد از اجرا:

1. اپلیکیشن رو uninstall کن
2. دوباره نصب کن
3. آیکون جدید رو در لانچر می‌بینی

## 📱 آیکون جدید:

- لوگو: `app_logo.png`
- پس‌زمینه: سبز (#66BB6A)
- Adaptive Icon برای Android 8.0+

## 🎯 یکجا (کپی و paste کن):

```bash
flutter pub get && dart run flutter_launcher_icons && flutter clean && flutter pub get && flutter run
```

---

**نکته**: اگر دستورات کار نکرد، Terminal رو ببند و دوباره باز کن، سپس دستورات رو اجرا کن.
