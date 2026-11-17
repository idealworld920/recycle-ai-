import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_errors.dart';
import '../household/household_repository.dart';
import '../../core/analytics.dart';

/// 설정 → 내 데이터 삭제. 서버 users/{uid} 하위 전부 + 기기 초기화 + 익명 계정 삭제 → 온보딩으로.
Future<void> showDeleteDataSheet(BuildContext context) {
  Analytics.screen('delete_confirm');
  return showAppSheet(
    context,
    title: '내 데이터 삭제',
    initialSize: 0.5,
    builder: (ctx, controller) {
      final t = ctx.text;
      final c = ctx.colors;
      return ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        children: [
          Row(children: [const MascotImage(Mascot.crying, size: 56), const SizedBox(width: AppSpacing.sm), Icon(Symbols.delete_forever_rounded, size: 24, color: c.error)]),
          const SizedBox(height: AppSpacing.md),
          Text('정말 모두 지울까요?', style: t.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text('서버와 이 기기에서 다음이 즉시, 영구히 삭제돼요.', style: t.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final line in const ['분류 기록과 썸네일', '수거일 설정과 체크 기록', '도감, 질문 사용량', '계정(구글 연결 포함)과 동의 기록'])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('•  $line', style: t.bodySmall),
            ),
          const SizedBox(height: AppSpacing.md),
          Text('구독은 Google Play 에서 따로 해지해야 해요. 가족 공유 집은 자동으로 나가져요.', style: t.bodySmall),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await runDataDeletion(context);
            },
            child: const Text('전부 삭제'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        ],
      );
    },
  );
}

/// 삭제 흐름: 확인 → 로딩 시트("삭제하고 있어요…") → deleteUserData 함수 → Auth 계정 삭제 → RevenueCat logOut
/// → 기기 전부 초기화 → 온보딩 플래그 초기화 → 스플래시 첫 실행 분기. 실패하면 시트에 [다시 시도].
/// 함수가 아직 배포 전(not-found/unimplemented)이면 클라이언트에서 지우는 예전 방식으로 폴백한다.
Future<void> runDataDeletion(BuildContext context) async {
  final services = AppServices.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context);
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => _DeletionSheet(services: services),
  );
  if (ok != true) return;
  nav.popUntil((r) => r.isFirst);
  messenger.showSnackBar(const SnackBar(content: Text('데이터를 모두 삭제했어요.')));
  services.settings.notifyReset(); // → RecycleApp: 스플래시(첫 실행) → 온보딩 1페이지
}

/// 실제 삭제 단계. 함수 호출이 핵심이고 나머지는 기기 정리.
class DataDeleter {
  DataDeleter._();

  static const callableName = 'deleteUserData';

  /// 서버 삭제 + 계정 삭제 + 기기 초기화. 실패하면 throw (문구는 [messageOf]).
  static Future<Duration> run(AppServices services, {HouseholdBackend? backend}) async {
    final sw = Stopwatch()..start();
    debugPrint('[delete] 시작 uid=${services.auth.uid}');
    Analytics.log('data_delete_start');
    if (services.firebase.ready) {
      try {
        final r = await (backend ?? FunctionsBackend()).call(callableName, const {});
        debugPrint('[delete] 서버 삭제 완료 ${r['ms']}ms');
        await services.auth.service.deleteAuthAccountOnly();
      } on HouseholdException catch (e) {
        if (!e.notDeployed) rethrow;
        // 함수 미배포: 예전처럼 클라이언트에서 삭제.
        debugPrint('[delete] 함수 없음 → 클라이언트 삭제 폴백');
        await services.auth.service.deleteAccount();
      }
    }
    await services.leaveAccountLocally(); // RevenueCat logOut + 기록·도감·수거일·일정·집 캐시
    await services.settings.resetAll(); // 온보딩·동의·안내 플래그 초기화 (installedAt 은 새로)
    sw.stop();
    debugPrint('[delete] 완료 ${sw.elapsedMilliseconds}ms, 새 익명 uid=${services.auth.uid}');
    Analytics.log('data_delete_done', {'elapsed_ms': sw.elapsedMilliseconds});
    return sw.elapsed;
  }

  static String messageOf(Object e) => e is HouseholdException ? e.message : AuthErrors.message(e);
}

class _DeletionSheet extends StatefulWidget {
  const _DeletionSheet({required this.services});

  final AppServices services;

  @override
  State<_DeletionSheet> createState() => _DeletionSheetState();
}

class _DeletionSheetState extends State<_DeletionSheet> {
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await DataDeleter.run(widget.services);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('[delete] 실패 ${AuthErrors.code(e)} $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = DataDeleter.messageOf(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_busy) ...[
              Row(
                children: [
                  const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  const SizedBox(width: AppSpacing.md),
                  Text('삭제하고 있어요…', style: t.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('서버와 이 기기의 데이터를 지우는 중이에요. 잠시만 기다려 주세요.', style: t.bodyMedium?.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.md),
            ] else ...[
              Text('삭제에 실패했어요. 다시 시도해 주세요', style: t.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(_error ?? '', style: t.bodyMedium?.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('닫기'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: c.onInk),
                      onPressed: _start,
                      child: const Text('다시 시도'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
