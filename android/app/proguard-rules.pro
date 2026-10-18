# ReSAI 릴리스(R8) 규칙.
# 디버그에선 멀쩡한데 릴리스에서만 스플래시에 멈추는 전형적 원인이 R8 이 플러그인 클래스를
# 지우거나 제네릭 시그니처를 떼어내는 것이라, 쓰는 플러그인은 통째로 남긴다.

# 앱 자신 (홈 위젯 리시버, MainActivity)
-keep class com.idealworld.recycle_ai.** { *; }

# Flutter 엔진·플러그인 등록
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ★ 릴리스에서 스플래시에 멈추던 실제 원인.
# shared_preferences_android 2.5 / path_provider_android 2.3 은 Pigeon JNI(jnigen) 로 Dart 가 자바
# 메서드를 "이름 + 시그니처 문자열" 로 찾는다. 시그니처에 kotlin.coroutines.Continuation 같은 코틀린
# 클래스가 들어가는데 R8 이 그 이름을 바꾸면 NoSuchMethodError 로 SharedPreferences 가 죽는다.
# 그래서 시그니처에 등장하는 클래스는 이름까지 그대로 둔다.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker { *; }
-keep class kotlin.enums.EnumEntries { *; }
-keep class kotlin.Unit { *; }
-keep class kotlinx.coroutines.** { *; }
-keepnames class kotlin.** { *; }

# Firebase / Google Play services (Auth, Firestore, App Check, AI Logic, Play Integrity)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.integrity.**

# flutter_local_notifications: 예약 알림을 GSON 으로 저장한다.
# R8 full mode 가 Signature 를 지우면 TypeToken 에서 "Missing type parameter" 로 죽는다.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature, InnerClasses, EnclosingMethod, *Annotation*
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**

# home_widget / workmanager (백그라운드 콜백·리시버)
-keep class es.antonborri.home_widget.** { *; }
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class androidx.work.** { *; }
-dontwarn es.antonborri.home_widget.**
-dontwarn dev.fluttercommunity.workmanager.**

# RevenueCat / Play Billing
-keep class com.revenuecat.** { *; }
-keep class com.android.billingclient.** { *; }
-dontwarn com.revenuecat.**
-dontwarn com.android.billingclient.**

# Firestore(gRPC)·네트워크 스택이 참조만 하는, 안드로이드에 없는 클래스들. 없어도 동작한다.
-dontwarn io.grpc.**
-dontwarn com.google.protobuf.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.j2objc.annotations.**
-dontwarn com.google.auto.value.**
-dontwarn com.google.api.client.**
-dontwarn com.google.crypto.tink.**
-dontwarn org.checkerframework.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn javax.annotation.**
-dontwarn javax.naming.**
-dontwarn javax.lang.model.**
-dontwarn java.lang.invoke.**
-dontwarn sun.misc.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn kotlinx.coroutines.**
-dontwarn kotlin.**
-dontwarn androidx.**
