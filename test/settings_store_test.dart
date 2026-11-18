import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_ai/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('동의 저장과 온보딩 플래그', () async {
    final s = await SettingsStore.load();
    expect(s.onboarded, isFalse);
    expect(s.consentedRequired, isFalse);
    await s.saveConsent(terms: true, privacy: true, marketing: false, version: '2026-11');
    await s.setOnboarded(true);
    expect(s.consentedRequired, isTrue);
    expect(s.consentVersion, '2026-11');
    expect(s.consentRemotePending, isTrue);
    expect(s.consentDoc['marketing'], false);
    expect(s.consentedMarketing, isFalse);
    expect(s.onboarded, isTrue);
  });

  test('권한 안내는 종류별 한 번', () async {
    final s = await SettingsStore.load();
    expect(s.primerShown('camera'), isFalse);
    await s.markPrimerShown('camera');
    expect(s.primerShown('camera'), isTrue);
    expect(s.primerShown('notification'), isFalse);
  });

  group('온보딩 이관 (1.3.1)', () {
    test('새 설치(빈 prefs)는 온보딩을 본다', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsStore.load();
      expect(s.onboarded, isFalse);
      expect(s.migratedThisLaunch, isFalse);
    });

    test('플래그 없이 기록·수거일·지역 같은 사용 흔적이 있으면 완료로 이관한다', () async {
      for (final seed in <Map<String, Object>>[
        {'history_v2': <String>['{"id":"a"}']},
        {'pickup_schedule_v1': '{"days":{}}'},
        {'region_code_v2': '11440'},
        {'collection_v1': <String>['pet']},
        {'free_classify_2026-11-17': 3},
        {'consent_terms': true},
      ]) {
        SharedPreferences.setMockInitialValues({'installed_at_v1': '2026-10-01T00:00:00', ...seed});
        final s = await SettingsStore.load();
        expect(s.onboarded, isTrue, reason: seed.keys.first);
        expect(s.migratedThisLaunch, isTrue, reason: seed.keys.first);
        // 다음 실행에선 이관이 아니라 그냥 완료
        final again = await SettingsStore.load();
        expect(again.onboarded, isTrue);
        expect(again.migratedThisLaunch, isFalse);
      }
    });

    test('온보딩 도중 앱을 껐다 켠 새 사용자는 이관되지 않는다 (installed_at·last/prev_opened 만 있음)', () async {
      SharedPreferences.setMockInitialValues({'installed_at_v1': '2026-11-17T00:00:00', 'last_opened_at': 1, 'prev_opened_at': 1, 'ribbong_bubble_logged_day': '2026-11-17'});
      final s = await SettingsStore.load();
      expect(s.onboarded, isFalse);
    });

    test('빈 기록 리스트는 흔적이 아니다', () async {
      SharedPreferences.setMockInitialValues({'history_v2': <String>[], 'collection_v1': <String>[]});
      final s = await SettingsStore.load();
      expect(s.onboarded, isFalse);
    });

    test('데이터 삭제 뒤에는 흔적이 남아도 온보딩을 다시 본다 (명시적 false)', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsStore.load();
      await s.setOnboarded(true);
      await s.resetAll();
      expect(s.onboarded, isFalse);
      final again = await SettingsStore.load();
      expect(again.onboarded, isFalse);
      expect(again.migratedThisLaunch, isFalse);
    });

    test('이미 완료(onboardingDone 또는 onboarded_v1)면 그대로', () async {
      SharedPreferences.setMockInitialValues({'onboarded_v1': true});
      expect((await SettingsStore.load()).onboarded, isTrue);
      SharedPreferences.setMockInitialValues({'onboardingDone': true, 'history_v2': <String>['x']});
      final s = await SettingsStore.load();
      expect(s.onboarded, isTrue);
      expect(s.migratedThisLaunch, isFalse);
    });
  });

  test('내 데이터 삭제 시 전부 초기화', () async {
    final s = await SettingsStore.load();
    await s.saveConsent(terms: true, privacy: true, marketing: true, version: '2026-11');
    await s.setOnboarded(true);
    await s.resetAll();
    expect(s.onboarded, isFalse);
    expect(s.consentedRequired, isFalse);
    expect(s.daysSinceInstall, 0);
  });
}
