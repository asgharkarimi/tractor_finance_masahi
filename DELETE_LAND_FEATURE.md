# 🗑️ قابلیت حذف زمین

## ویژگی جدید
آیکون حذف در گوشه بالا سمت راست هر کارت زمین

## 🎨 طراحی

### مکان آیکون
```
┌─────────────────────────────────┐
│                            [🗑️] │ ← گوشه بالا راست
│                                 │
│         [عکس زمین]              │
│                                 │
│  📏 1.3 هکتار    💰 1,690,000   │
└─────────────────────────────────┘
```

### ویژگی‌های آیکون
- **رنگ**: قرمز
- **پس‌زمینه**: سفید
- **سایه**: ملایم
- **شکل**: دایره
- **اندازه**: 20px
- **Padding**: 8px

## 🔄 جریان کار

### مراحل حذف
1. کاربر روی آیکون حذف کلیک می‌کند
2. دیالوگ تایید نمایش داده می‌شود
3. اگر نام زمین دارد: "آیا از حذف 'نام زمین' مطمئن هستید؟"
4. اگر نام ندارد: "آیا از حذف این زمین مطمئن هستید؟"
5. کاربر تایید یا رد می‌کند
6. در صورت تایید، زمین حذف می‌شود

### کد دیالوگ
```dart
AlertDialog(
  title: const Text('حذف زمین'),
  content: Text(
    land.name != null
        ? 'آیا از حذف "${land.name}" مطمئن هستید؟'
        : 'آیا از حذف این زمین مطمئن هستید؟',
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: const Text('خیر'),
    ),
    TextButton(
      onPressed: () => Navigator.pop(context, true),
      child: const Text('بله'),
    ),
  ],
)
```

## 💡 ویژگی‌های خاص

### 1. آیکون شناور
- با `Positioned` در گوشه قرار گرفته
- روی عکس یا محتوای کارت قرار می‌گیرد
- همیشه قابل دسترسی

### 2. طراحی زیبا
- پس‌زمینه سفید با سایه
- کنتراست خوب با محتوا
- قابل تشخیص آسان

### 3. تایید هوشمند
- اگر زمین نام دارد، نام را نمایش می‌دهد
- پیام واضح و قابل فهم
- جلوگیری از حذف تصادفی

## 🔧 تغییرات فنی

### ساختار جدید
```dart
Stack(
  children: [
    Column(
      // محتوای کارت زمین
    ),
    // آیکون حذف
    Positioned(
      top: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 20,
          ),
          onPressed: () => _deleteLand(context, farmer, land),
        ),
      ),
    ),
  ],
)
```

### متد حذف
```dart
void _deleteLand(BuildContext context, Farmer farmer, Land land) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('حذف زمین'),
      content: Text(
        land.name != null
            ? 'آیا از حذف "${land.name}" مطمئن هستید؟'
            : 'آیا از حذف این زمین مطمئن هستید؟',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('خیر'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('بله'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    farmer.lands.remove(land);
    await farmer.save();
  }
}
```

## 🎯 مزایا

### برای کاربر
- ✅ دسترسی سریع به حذف
- ✅ بدون نیاز به ورود به صفحه ویرایش
- ✅ تایید قبل از حذف
- ✅ پیام واضح

### برای تجربه کاربری
- ✅ کاهش تعداد کلیک‌ها
- ✅ جلوگیری از حذف تصادفی
- ✅ بازخورد فوری
- ✅ طراحی شهودی

## 📊 مقایسه

### قبل
- بدون قابلیت حذف مستقیم
- نیاز به ویرایش کشاورز
- پیچیده و زمان‌بر

### حالا
- ✅ آیکون حذف در هر کارت
- ✅ حذف مستقیم با یک کلیک
- ✅ ساده و سریع

## ⚠️ نکات ایمنی

1. **تایید الزامی**: همیشه دیالوگ تایید نمایش داده می‌شود
2. **پیام واضح**: کاربر می‌داند چه چیزی حذف می‌شود
3. **قابل برگشت**: با دکمه "خیر" قابل لغو است
4. **ذخیره خودکار**: بعد از حذف، تغییرات ذخیره می‌شود

## 🔄 به‌روزرسانی‌های آینده

### پیشنهادات
- [ ] قابلیت Undo (بازگردانی)
- [ ] حذف چندتایی
- [ ] آرشیو به جای حذف
- [ ] تاریخچه حذف‌ها

---

**نتیجه**: حذف زمین حالا خیلی ساده‌تر و سریع‌تر شده! 🎉
