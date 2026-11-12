import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_services.dart';
import '../../core/analytics.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/waste_group.dart';
import '../../widgets/app_card.dart';
import '../auth/link_flows.dart';
import '../auth/locked_overlay.dart';
import '../places/external_links.dart';
import '../share/share_card.dart';
import 'report_calculator.dart';
import 'report_share_card.dart';

/// 월간 리포트. 집계는 전부 기기에서, 50건 이상이면 users/{uid}/reports/{yyyy-MM} 에 요약을 캐시한다.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.month});

  final DateTime month;

  static const disclaimer = ReportShareCard.caption;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  MonthlyReport? _report;
  bool _sharing = false;
  bool _logged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppServices.of(context);
    _report = ReportCalculator.build(
      month: widget.month,
      history: s.history.items,
      checkinDates: s.schedule.checkinDates,
      schedule: s.schedule.schedule,
      tips: s.tips,
      factors: s.carbon,
    );
    if (!_logged) {
      _logged = true;
      Analytics.log('report_viewed', {'month': _report!.key, 'total': _report!.total});
      _cacheIfLarge(s, _report!);
    }
  }

  Future<void> _cacheIfLarge(AppServices s, MonthlyReport r) async {
    if (r.total < 50 || !s.firebase.ready || s.firebase.uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(s.firebase.uid).collection('reports').doc(r.key).set({
        'total': r.total,
        'recycleRate': r.recycleRate,
        'counts': {for (final e in r.counts.entries) e.key.name: e.value},
        'top': [for (final t in r.topItems) {'name': t.name, 'count': t.count}],
        'carbonKg': r.carbon.showable ? r.carbon.kg : null,
        'checkins': r.checkinCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('리포트 캐시 실패: $e');
    }
  }

  Future<void> _share() async {
    final r = _report;
    if (r == null || _sharing) return;
    final story = await showAppSheet<bool>(
      context,
      title: '어떤 크기로 공유할까요?',
      initialSize: 0.4,
      maxSize: 0.5,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        children: [
          ListTile(leading: const Icon(Symbols.crop_portrait_rounded), title: const Text('피드용 (4:5)'), subtitle: const Text('1080 x 1350'), onTap: () => Navigator.pop(ctx, false)),
          ListTile(leading: const Icon(Symbols.smartphone_rounded), title: const Text('스토리용 (9:16)'), subtitle: const Text('1080 x 1920'), onTap: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (story == null || !mounted) return;
    setState(() => _sharing = true);
    final c = context.colors;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final png = await ReportShareCard.render(r, story: story, primary: c.primary, ink: c.ink, surface: c.surface, textSecondary: c.textSecondary, divider: c.divider);
      final text = '${r.title}: 분류 ${r.total}개, 재활용률 ${r.recycleRate ?? '-'}%'
          '${r.carbon.showable ? ', 탄소 약 ${r.carbon.kg.toStringAsFixed(1)}kg 절감(추정)' : ''} · ReSAI https://${ShareCard.shortUrl}';
      if (kIsWeb) {
        await SharePlus.instance.share(ShareParams(text: text, sharePositionOrigin: origin));
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/resai_report_${r.key}.png');
        await file.writeAsBytes(png, flush: true);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'image/png')], text: text, sharePositionOrigin: origin));
      }
      Analytics.log('report_shared', {'month': r.key, 'format': story ? 'story' : 'feed'});
    } catch (e) {
      debugPrint('리포트 공유 실패: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유 이미지를 만들지 못했어요.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report!;
    final c = context.colors;
    final t = context.text;
    final services = AppServices.of(context);
    final anonymous = services.auth.isAnonymous;
    void connect() => connectGoogle(context);
    final happy = r.improvedOrSame;

    return Scaffold(
      appBar: AppBar(
        title: const Text('월간 리포트'),
        actions: [IconButton(onPressed: _sharing ? null : _share, icon: const Icon(Symbols.share_rounded), tooltip: '공유')],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          // ① 헤더
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title, style: t.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(happy ? '이번 달도 잘했뿅!' : '다음 달엔 같이 올려보자뿅!', style: t.bodyMedium?.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              MascotImage(happy ? Mascot.happy : Mascot.idle, size: 88),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ② 총 분류 수
          _StatCard(
            label: '총 분류',
            value: '${r.total}개',
            delta: _delta(r.totalChange, unit: '개', compare: r.prevTotal > 0 || r.total > 0),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ③ 재활용률 (+ 지난달 대비는 연결 후)
          _StatCard(
            label: '재활용률',
            value: r.recycleRate == null ? '-' : '${r.recycleRate}%',
            deltaWidget: LockedOverlay(
              locked: anonymous,
              message: '지난달 대비는 연결 후 볼 수 있어요',
              onConnect: connect,
              child: _delta(r.rateChange, unit: '%p', compare: r.rateChange != null) ?? Text('지난달 기록이 없어요', style: t.bodySmall),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ④ 카테고리 비율 바
          Text('무엇을 많이 버렸나', style: t.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _GroupBar(counts: r.counts, total: r.total),
          const SizedBox(height: AppSpacing.xl),

          // ⑤ TOP3
          if (r.topItems.isNotEmpty) ...[
            Text('가장 많이 분류한 품목', style: t.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < r.topItems.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: i == 0 ? c.primary : c.ink, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: t.labelLarge?.copyWith(color: c.onInk, fontSize: 12, height: 1)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(r.topItems[i].name, style: t.bodyMedium)),
                    Text('${r.topItems[i].count}회', style: t.bodySmall),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ⑥ 탄소 절감
          Text('탄소 절감 환산', style: t.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (r.carbon.showable)
            AppCard(
              soft: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('약 ${r.carbon.kg.toStringAsFixed(1)} kg CO₂e', style: t.headlineSmall?.copyWith(color: c.primary)),
                  if (r.carbon.trees != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('소나무 약 ${_trees(r.carbon.trees!)}그루 1년 흡수량', style: t.bodyMedium),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text('계수가 있는 품목 ${r.carbon.coveredCount}/${r.carbon.totalCount}개 기준', style: t.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () => _showBasis(context, r),
                    icon: const Icon(Symbols.info_rounded, size: 18),
                    label: const Text('계산 기준 보기'),
                  ),
                ],
              ),
            )
          else
            AppCard(
              soft: true,
              child: Row(
                children: [
                  Icon(Symbols.hourglass_empty_rounded, size: 20, color: c.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('데이터가 더 쌓이면 보여드릴게요', style: t.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),

          // ⑦ 수거일 체크 + 스트릭
          Text('수거일 체크', style: t.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _StatCard(
            label: '이번 달 체크',
            value: '${r.checkinCount}회',
            deltaWidget: LockedOverlay(
              locked: anonymous,
              message: '스트릭 기록은 연결 후 볼 수 있어요',
              onConnect: connect,
              child: Text(r.streakWeeks > 0 ? '🔥 ${r.streakWeeks}주 연속' : '이달 말 기준 연속 기록 없음', style: t.bodySmall),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ⑧ 공유
          FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: const Icon(Symbols.share_rounded, size: 20),
            label: Text(_sharing ? '만드는 중…' : '리포트 공유하기'),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ⑨ 고정 문구
          Text(ReportScreen.disclaimer, style: t.bodySmall?.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }

  static String _trees(double v) => v < 1 ? v.toStringAsFixed(1) : v.toStringAsFixed(v < 10 ? 1 : 0);

  Widget? _delta(int? change, {required String unit, required bool compare}) {
    if (change == null || !compare) return null;
    final c = context.colors;
    final t = context.text;
    final up = change > 0;
    final color = up ? c.primary : c.textSecondary; // 빨강 금지
    final icon = change == 0 ? Symbols.remove_rounded : (up ? Symbols.arrow_upward_rounded : Symbols.arrow_downward_rounded);
    final label = change == 0 ? '지난달과 같아요' : '지난달보다 ${change.abs()}$unit ${up ? '늘었어요' : '줄었어요'}';
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: color), const SizedBox(width: AppSpacing.xs), Text(label, style: t.bodySmall?.copyWith(color: color))]);
  }

  void _showBasis(BuildContext context, MonthlyReport r) {
    showAppSheet<void>(
      context,
      title: '계산 기준',
      initialSize: 0.7,
      builder: (ctx, controller) {
        final t = ctx.text;
        final c = ctx.colors;
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          children: [
            Text('품목 수 × 품목별 계수를 더한 값이에요. 계수가 없는 품목은 더하지 않았어요.', style: t.bodyMedium),
            const SizedBox(height: AppSpacing.base),
            for (final u in r.carbon.used)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${u.label} × ${u.count} = 약 ${u.kg.toStringAsFixed(2)} kg', style: t.titleSmall),
                    Text('${u.factor.kgCO2e} ${u.factor.unit}${u.factor.typicalWeightKg != null ? ' · 1개 ${u.factor.typicalWeightKg} kg' : ''} · ${u.factor.basis}', style: t.bodySmall),
                    InkWell(
                      onTap: () => ExternalLinks.open(u.factor.source.url),
                      child: Text(u.factor.source.label, style: t.bodySmall?.copyWith(color: c.primary, decoration: TextDecoration.underline)),
                    ),
                    if (u.factor.weightSource != null)
                      InkWell(
                        onTap: () => ExternalLinks.open(u.factor.weightSource!.url),
                        child: Text('무게: ${u.factor.weightSource!.label}', style: t.bodySmall?.copyWith(color: c.primary, decoration: TextDecoration.underline)),
                      ),
                  ],
                ),
              ),
            if (r.carbon.pine != null) ...[
              const Divider(),
              Text('소나무 환산: 1그루 연간 ${r.carbon.pine!.kgPerTreePerYear} kg CO₂ 흡수 ${r.carbon.pine!.basis.isNotEmpty ? '(${r.carbon.pine!.basis})' : ''}', style: t.bodySmall),
              InkWell(
                onTap: () => ExternalLinks.open(r.carbon.pine!.source.url),
                child: Text(r.carbon.pine!.source.label, style: t.bodySmall?.copyWith(color: c.primary, decoration: TextDecoration.underline)),
              ),
            ],
            const SizedBox(height: AppSpacing.base),
            Text(ReportScreen.disclaimer, style: t.bodySmall),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.delta, this.deltaWidget});

  final String label;
  final String value;
  final Widget? delta;
  final Widget? deltaWidget;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final sub = deltaWidget ?? delta;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: t.headlineSmall),
              ],
            ),
          ),
          if (sub != null) Flexible(child: Align(alignment: Alignment.centerRight, child: sub)),
        ],
      ),
    );
  }
}

class _GroupBar extends StatelessWidget {
  const _GroupBar({required this.counts, required this.total});

  final Map<WasteGroup, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    if (total == 0) return Text('이 달엔 분류 기록이 없어요', style: t.bodySmall);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: SizedBox(
            height: 14,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in WasteGroup.values)
                  if ((counts[g] ?? 0) > 0) Expanded(flex: counts[g]!, child: ColoredBox(color: c.groupColor(g))),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.base,
          runSpacing: AppSpacing.xs,
          children: [
            for (final g in WasteGroup.values)
              if ((counts[g] ?? 0) > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: c.groupColor(g), shape: BoxShape.circle)),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${g.label} ${(counts[g]! * 100 / total).round()}%', style: t.bodySmall),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}
