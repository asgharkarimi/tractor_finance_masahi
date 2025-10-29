# راهنمای تنظیم Google Maps

## مراحل دریافت API Key (رایگان):

### 1. ورود به Google Cloud Console
- به آدرس https://console.cloud.google.com بروید
- با اکانت گوگل خود وارد شوید

### 2. ساخت پروژه جدید
- روی منوی بالا کلیک کنید
- "New Project" را انتخاب کنید
- یک نام برای پروژه انتخاب کنید (مثلاً: TractorApp)
- روی "Create" کلیک کنید

### 3. فعال‌سازی Maps SDK
- از منوی سمت چپ، به "APIs & Services" > "Library" بروید
- "Maps SDK for Android" را جستجو کنید
- روی آن کلیک کنید
- دکمه "Enable" را بزنید

### 4. دریافت API Key
- از منوی سمت چپ، به "APIs & Services" > "Credentials" بروید
- روی "Create Credentials" کلیک کنید
- "API Key" را انتخاب کنید
- API Key شما ساخته می‌شود و نمایش داده می‌شود
- آن را کپی کنید

### 5. تنظیم API Key در اپلیکیشن

فایل `android/app/src/main/AndroidManifest.xml` را باز کنید و این خط را پیدا کنید:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

`YOUR_API_KEY_HERE` را با API Key خودتان جایگزین کنید:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyD..."/>
```

### 6. اجرای مجدد اپلیکیشن
```bash
flutter clean
flutter pub get
flutter run
```

## نکات مهم:

### ✅ رایگان است
- Google Maps برای استفاده شخصی و تعداد محدود درخواست رایگان است
- تا 28,000 بارگذاری نقشه در ماه رایگان

### ⚠️ محدودیت API Key (اختیاری اما توصیه می‌شود)
برای امنیت بیشتر، API Key را محدود کنید:

1. در صفحه Credentials، روی API Key خود کلیک کنید
2. در قسمت "Application restrictions":
   - "Android apps" را انتخاب کنید
   - Package name را اضافه کنید: `com.example.tractor_finance_manage`
   - SHA-1 fingerprint را اضافه کنید (اختیاری)

3. در قسمت "API restrictions":
   - "Restrict key" را انتخاب کنید
   - فقط "Maps SDK for Android" را انتخاب کنید

### 🔍 دریافت SHA-1 Fingerprint (اختیاری)
```bash
cd android
./gradlew signingReport
```

## عیب‌یابی:

### نقشه نمایش داده نمی‌شود؟
1. ✅ API Key را چک کنید
2. ✅ Maps SDK for Android را فعال کنید
3. ✅ اتصال اینترنت را بررسی کنید
4. ✅ اپلیکیشن را کاملاً ببندید و دوباره باز کنید

### خطای "Authorization failure"؟
- API Key اشتباه است
- Maps SDK فعال نیست
- محدودیت‌های API Key درست تنظیم نشده

## بدون API Key چی میشه؟
- نقشه نمایش داده نمی‌شود
- یک صفحه خاکستری با پیام خطا نمایش داده می‌شود
- باید حتماً API Key را تنظیم کنید
