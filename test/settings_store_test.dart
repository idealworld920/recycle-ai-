import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('동의 저장과 온보딩 플래그', () async {
    final s = await SettingsStore.load();
    expect(s.onboarded, isFalse);
    expect(s.consentedRequired, isFalse);
    await s.saveConsent(terms: true, privacy: true, notifications: false, version: '1.0');
    await s.setOnboarded(true);
    expect(s.consentedRequired, isTrue);
    expect(s.consentVersion, '1.0');
    expect(s.consentedNotifications, isFalse);
    expect(s.onboarded, isTrue);
  });

  test('권한 안내는 종류별 한 번', () async {
    final s = await SettingsStore.load();
    expect(s.primerShown('camera'), isFalse);
    await s.markPrimerShown('camera');
    expect(s.primerShown('camera'), isTrue);
    expect(s.primerShown('notification'), isFalse);
  });

  test('내 데이터 삭제 시 전부 초기화', () async {
    final s = await SettingsStore.load();
    await s.saveConsent(terms: true, privacy: true, notifications: true, version: '1.0');
    await s.setOnboarded(true);
    await s.resetAll();
    expect(s.onboarded, isFalse);
    expect(s.consentedRequired, isFalse);
    expect(s.daysSinceInstall, 0);
  });
}
