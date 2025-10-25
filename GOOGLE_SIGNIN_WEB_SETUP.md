# Google Sign-In على الويب - دليل الإعداد

## ⚠️ المشكلة الحالية

Google Sign-In على الويب يُظهر خطأ `popup_closed` لأن Google تطلب الآن استخدام **Google Identity Services (GIS)** بدلاً من الطريقة القديمة.

## 🔧 الحل المؤقت

حالياً، التطبيق يستخدم:
- **للويب**: `signInSilently()` فقط (لا يفتح popup)
- **للموبايل/ديسكتوب**: `signIn()` العادي

## ✅ خطوات إعداد Google Cloud Console

### 1. افتح Google Cloud Console
اذهب إلى: https://console.cloud.google.com/

### 2. اختر مشروعك أو أنشئ واحد جديد

### 3. تفعيل Google+ API
- انتقل إلى **APIs & Services** > **Library**
- ابحث عن "Google+ API"
- اضغط **Enable**

### 4. إعداد OAuth consent screen
- انتقل إلى **APIs & Services** > **OAuth consent screen**
- اختر **External**
- املأ المعلومات المطلوبة:
  - App name: اسم تطبيقك
  - User support email: بريدك الإلكتروني
  - Developer contact information: بريدك الإلكتروني

### 5. إنشاء OAuth 2.0 Client IDs

#### للويب:
- انتقل إلى **APIs & Services** > **Credentials**
- اضغط **Create Credentials** > **OAuth client ID**
- اختر **Web application**
- أضف **Authorized JavaScript origins**:
  ```
  http://localhost:8080
  http://localhost:3000
  http://localhost:5000
  https://your-production-domain.com
  ```
- أضف **Authorized redirect URIs**:
  ```
  http://localhost:8080/
  http://localhost:3000/
  http://localhost:5000/
  https://your-production-domain.com/
  ```

#### للأندرويد:
- انتقل إلى **Create Credentials** > **OAuth client ID**
- اختر **Android**
- أدخل:
  - Package name: `com.example.real` (أو package name من `android/app/build.gradle`)
  - SHA-1: احصل عليه بتشغيل:
    ```bash
    cd android
    ./gradlew signingReport
    ```

#### لـ iOS:
- اختر **iOS**
- أدخل Bundle ID من `ios/Runner.xcodeproj/project.pbxproj`

### 6. انسخ Client ID
- انسخ **Client ID** الخاص بالويب
- ضعه في:
  - `lib/feature_web/auth/presentation/web_login_screen.dart` (سطر 38)
  - `web/index.html` (سطر 24)

## 🌐 للتشغيل على الويب

```bash
# تأكد من المنفذ (port)
flutter run -d chrome --web-port=8080

# أو
flutter run -d chrome --web-port=3000
```

**مهم**: المنفذ يجب أن يكون نفسه المُضاف في Google Console!

## 📱 الحل البديل

إذا استمرت المشكلة على الويب:
1. استخدم **Email/Password** للتسجيل
2. أو انتظر حتى يتم تطبيق Google Identity Services بالكامل

## 🔍 فحص الأخطاء

### إذا ظهر `popup_closed`:
- ✅ تحقق من أن المنفذ مُضاف في Google Console
- ✅ تأكد من السماح بالـ popups في المتصفح
- ✅ تحقق من أنك مُسجل دخول في Google

### إذا ظهر `invalid_client`:
- ❌ Client ID خاطئ أو غير مُفعّل
- ❌ Domain غير مُضاف في Authorized origins

### إذا ظهر `redirect_uri_mismatch`:
- ❌ Redirect URI غير مُضاف بشكل صحيح

## 📚 مراجع مفيدة

- [Google Sign-In Web Migration Guide](https://developers.google.com/identity/gsi/web/guides/migration)
- [Flutter google_sign_in Package](https://pub.dev/packages/google_sign_in)
- [Google Identity Services](https://developers.google.com/identity/gsi/web)

## 🚀 التحديثات المستقبلية

في المستقبل، سيتم تحديث الكود لاستخدام:
- `renderButton()` على الويب
- Google Identity Services مباشرة
- FedCM (Federated Credential Management)

---

**آخر تحديث**: 2025-01-25
