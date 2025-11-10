# 🏢 نظام علامات التحديثات على المجمعات - Compound Update Badges System

## 📋 نظرة عامة | Overview

نظام متكامل لعرض **badges/علامات مرئية** على كروت المجمعات عندما تحتوي على وحدات جديدة أو محدثة - **بدون الحاجة للدخول للمجمع**.

## ✨ الميزات | Features

- ✅ Badge على كرت المجمع يوضح عدد الوحدات الجديدة/المحدثة
- ✅ يظهر مباشرة على الشاشة الرئيسية (Web & Mobile)
- ✅ تكامل كامل مع نظام الإشعارات الموجود
- ✅ يختفي Badge بعد مشاهدة الوحدات

---

## 🔄 الدورة الكاملة | Complete Flow

```
1. Admin يضيف/يحدث وحدة
   ↓
2. Unit Observer يعمل تلقائياً
   ↓
3. is_updated = true على الوحدة
   ↓
4. API /compounds يحسب تلقائياً عدد الوحدات المحدثة
   ↓
5. Response يحتوي على: updated_units_count: 3
   ↓
6. Flutter يستقبل البيانات
   ↓
7. Badge يظهر على كرت المجمع: 🔴 3 NEW
   ↓
8. المستخدم يفتح المجمع
   ↓
9. الوحدات تظهر مع علامات "NEW"
   ↓
10. عند فتح وحدة → POST /units/{id}/mark-seen
   ↓
11. Badge يختفي تدريجياً عندما تقل الوحدات المحدثة
```

---

## 🎯 التعديلات المطلوبة | Required Changes

### 1. Backend - Laravel API

#### A. تعديل CompoundController.php

```php
public function index(Request $request)
{
    $query = Compound::with(['company', 'sales']);

    // ... existing filters ...

    // Add updated units count
    $query->withCount(['units as updated_units_count' => function ($q) {
        $q->where('is_updated', true);
    }]);

    $compounds = $query->paginate($limit);

    // Transform the data
    $data = $compounds->getCollection()->map(function ($compound) {
        $compoundArray = $compound->toArray();

        // Add updated units count to response
        $compoundArray['updated_units_count'] = $compound->updated_units_count ?? 0;

        return $compoundArray;
    });

    return response()->json([
        'success' => true,
        'data' => $data,
        'meta' => [
            'current_page' => $compounds->currentPage(),
            'total' => $compounds->total(),
            'per_page' => $compounds->perPage(),
        ],
    ]);
}
```

#### B. تعديل compound/{id} endpoint

```php
public function show($id, Request $request)
{
    $lang = $request->query('lang', 'en');

    $compound = Compound::with(['company', 'sales'])
        ->withCount(['units as updated_units_count' => function ($q) {
            $q->where('is_updated', true);
        }])
        ->findOrFail($id);

    $compoundArray = $compound->toArray();
    $compoundArray['updated_units_count'] = $compound->updated_units_count ?? 0;

    return response()->json([
        'success' => true,
        'data' => $compoundArray,
    ]);
}
```

---

### 2. Frontend - Flutter

#### A. تحديث CompoundModel

```dart
class Compound extends Equatable {
  // ... existing fields ...

  final int updatedUnitsCount; // 🆕 NEW FIELD

  Compound({
    // ... existing parameters ...
    this.updatedUnitsCount = 0, // 🆕 NEW PARAMETER
  });

  factory Compound.fromJson(Map<String, dynamic> json) {
    // ... existing parsing ...

    return Compound(
      // ... existing fields ...
      updatedUnitsCount: json['updated_units_count'] as int? ?? 0, // 🆕
    );
  }

  @override
  List<Object?> get props => [
    // ... existing props ...
    updatedUnitsCount, // 🆕
  ];
}
```

#### B. تحديث Web Compound Card

```dart
// في web_compound_card.dart
Stack(
  children: [
    // Existing image and buttons...

    // 🆕 NEW - Update Badge (top-left, after other buttons)
    if (compound.updatedUnitsCount > 0)
      Positioned(
        top: 8,
        left: showFavoriteButton ? 104 : 72,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fiber_new, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                '${compound.updatedUnitsCount}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
  ],
)
```

#### C. تحديث Mobile Compound Card

```dart
// في compound_card.dart (mobile)
Stack(
  children: [
    // Existing image...

    // 🆕 NEW - Update Badge
    if (compound.updatedUnitsCount > 0)
      Positioned(
        top: 12,
        right: 12,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fiber_new, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text(
                '${compound.updatedUnitsCount} NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
  ],
)
```

---

## 🎨 تصميم Badge | Badge Design

### الألوان | Colors
- **Background**: `Colors.red` (FF0000)
- **Text**: `Colors.white` (FFFFFF)
- **Shadow**: `Colors.red.withOpacity(0.4)`

### الأيقونة | Icon
- **Icon**: `Icons.fiber_new` أو `Icons.new_releases`
- **Size**: 14-16px

### النص | Text
- **Format**: `"3 NEW"` أو `"3"`
- **Font**: Bold, 11-12px
- **Letter Spacing**: 0.5

---

## 📱 أمثلة الاستخدام | Usage Examples

### 1. عرض المجمعات مع البادجات

```dart
// الحصول على المجمعات
final compoundWebServices = CompoundWebServices();
final response = await compoundWebServices.getCompounds(page: 1, limit: 20);

// كل مجمع يحتوي الآن على updated_units_count
for (var compound in response.data) {
  if (compound.updatedUnitsCount > 0) {
    print('${compound.project} has ${compound.updatedUnitsCount} new units');
  }
}
```

### 2. تحديث UI بعد مشاهدة وحدة

```dart
// عند فتح وحدة من المجمع
await http.post(
  Uri.parse('https://aqar.bdcbiz.com/api/units/$unitId/mark-seen')
);

// ثم تحديث قائمة المجمعات
context.read<CompoundBloc>().add(RefreshCompoundsEvent());

// Badge سيتحدث تلقائياً مع العدد الجديد
```

### 3. معالجة الإشعار وتحديث الشاشة

```dart
// عند استلام إشعار FCM
FirebaseMessaging.onMessage.listen((message) {
  if (message.data['action'] == 'new_unit' ||
      message.data['action'] == 'unit_updated') {

    // تحديث قائمة المجمعات لتظهر البادج
    context.read<CompoundBloc>().add(RefreshCompoundsEvent());

    // عرض SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New unit added in ${message.data['compound_name']}!'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // الانتقال للمجمع
            Navigator.push(context, ...);
          },
        ),
      ),
    );
  }
});
```

---

## 🔧 API Responses

### GET /api/compounds

```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "project": "205 Arkan Palm",
      "location": "El Sheikh Zayed",
      "company_name": "El Riviera",
      "total_units": "150",
      "available_units": "45",
      "updated_units_count": 3,  // 🆕 NEW
      "images": [...],
      ...
    },
    {
      "id": "2",
      "project": "205 DownTown",
      "updated_units_count": 0,  // No updates
      ...
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 50,
    "per_page": 20
  }
}
```

### GET /api/compounds/{id}

```json
{
  "success": true,
  "data": {
    "id": "1",
    "project": "205 Arkan Palm",
    "updated_units_count": 3,  // 🆕 NEW
    "units": [
      {
        "id": "123",
        "unit_number": "A-101",
        "is_updated": true,  // 🔴 NEW UNIT
        "last_changed_at": "2025-11-02 10:30:00",
        ...
      },
      {
        "id": "456",
        "unit_number": "B-205",
        "is_updated": true,  // 🔴 UPDATED UNIT
        ...
      }
    ]
  }
}
```

---

## ✅ قائمة التحقق | Checklist

### Backend
- [ ] إضافة `withCount` في `index()` method
- [ ] إضافة `withCount` في `show()` method
- [ ] إضافة `updated_units_count` في Response
- [ ] اختبار API بـ Postman

### Frontend
- [ ] إضافة `updatedUnitsCount` في `CompoundModel`
- [ ] تحديث `fromJson` لاستقبال الحقل الجديد
- [ ] إضافة Badge في `WebCompoundCard`
- [ ] إضافة Badge في Mobile `CompoundCard`
- [ ] ربط مع نظام `mark-seen`
- [ ] اختبار كامل على Web & Mobile

---

## 🎯 الحالة النهائية | Final State

### المستخدم يرى:

1. **على الشاشة الرئيسية:**
   ```
   [Image of Compound]
   🔴 3 NEW  ← Badge أحمر في أعلى الكرت
   205 Arkan Palm
   El Sheikh Zayed
   150 Units | 45 Available
   ```

2. **عند الدخول للمجمع:**
   ```
   Units List:
   - Unit A-101  🔴 NEW
   - Unit A-102
   - Unit B-205  🔴 UPDATED
   ```

3. **بعد فتح الوحدات:**
   ```
   [Image of Compound]
   🔴 1 NEW  ← العدد قل من 3 إلى 1
   205 Arkan Palm
   ```

4. **بعد مشاهدة جميع الوحدات:**
   ```
   [Image of Compound]
   (no badge) ← Badge اختفى
   205 Arkan Palm
   ```

---

## 🚀 الخطوة التالية | Next Steps

1. تطبيق التعديلات على Backend
2. تحديث Flutter Models
3. إضافة Badges على UI
4. اختبار النظام كامل
5. Deploy على Production

---

## 📞 الشرح | Explanation

### لماذا هذا النظام أفضل؟

1. **مرئي فوراً** - المستخدم يرى التحديثات بدون دخول
2. **غير مزعج** - Badge صغير وغير متداخل
3. **معلومات واضحة** - العدد الدقيق للوحدات الجديدة
4. **تفاعلي** - يختفي تلقائياً بعد المشاهدة
5. **متكامل** - يعمل مع نظام FCM الموجود

### كيف يعمل التكامل؟

```
Notification System  →  Badge System  →  Mark Seen API
      (FCM)              (Visual Cue)      (Update State)
       ↓                      ↓                  ↓
   "New unit!"        "🔴 3 NEW"         "is_updated=false"
```

---

تم إنشاء النظام بواسطة: Claude Code 🤖
التاريخ: 2025-11-02
