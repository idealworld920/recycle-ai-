import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../tips/tip_model.dart';
import 'external_links.dart';
import 'region_picker_sheet.dart';

/// 지역 기준 안내 박스.
///
/// - 사용자 지역에 검증된 노트가 있고 숨김 처리되지 않았으면 **파랑 박스**: "📍{시군구} 기준: {note}" + 출처 + 확인일 + "이 정보가 다른가요?"
/// - 없으면 **노란 박스**: "지자체별로 다를 수 있어요" + 구청 안내 페이지 링크(있을 때) 또는 지역 설정 버튼
/// - 지자체별로 갈리지 않는 품목(regionNotes 없음)이고 localNote 도 없으면 아무것도 안 그린다.
class RegionGuidance extends StatefulWidget {
  const RegionGuidance({super.key, required this.tip, this.compact = false});

  final Tip tip;

  /// 팁 카드 안처럼 좁은 곳.
  final bool compact;

  @override
  State<RegionGuidance> createState() => _RegionGuidanceState();
}

class _RegionGuidanceState extends State<RegionGuidance> {
  bool _hidden = false;
  String? _checkedKey;

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([services.region, services.feedback]),
      builder: (context, _) {
        final region = services.region.admin;
        final tip = widget.tip;
        final note = tip.noteFor(region?.code);
        if (note != null && region != null) {
          final key = '${region.code}_${tip.id}';
          if (_checkedKey != key) {
            _checkedKey = key;
            services.feedback.isRegionNoteHidden(region.code, tip.id).then((h) {
              if (mounted && h != _hidden) setState(() => _hidden = h);
            });
          }
          if (!_hidden) return _Verified(tip: tip, note: note, regionCode: region.code, regionName: region.displayName, compact: widget.compact);
        }
        if (!tip.isRegionVariant && !tip.hasLocalNote) return const SizedBox.shrink();
        return _Fallback(tip: tip, regionName: region?.name, guideUrl: region?.wasteGuideUrl, compact: widget.compact);
      },
    );
  }
}

class _Verified extends StatelessWidget {
  const _Verified({required this.tip, required this.note, required this.regionCode, required this.regionName, required this.compact});

  final Tip tip;
  final RegionNote note;
  final String regionCode;
  final String regionName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final feedback = AppServices.of(context).feedback;
    final reported = feedback.hasReportedRegionNote(regionCode, tip.id);
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.base),
      decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📍 $regionName 기준', style: t.titleSmall?.copyWith(color: c.primary)),
          const SizedBox(height: AppSpacing.xs),
          Text(note.note, style: t.bodyMedium?.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LinkText(label: '출처 보기', icon: Symbols.open_in_new_rounded, onTap: () => ExternalLinks.open(note.sourceUrl)),
              Text('확인일 ${note.verifiedAt}', style: t.bodySmall),
              _LinkText(
                label: reported ? '알려주셔서 고마워요' : '이 정보가 다른가요?',
                icon: reported ? Symbols.check_rounded : Symbols.flag_rounded,
                muted: true,
                onTap: reported ? null : () => _report(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _report(BuildContext context) async {
    final services = AppServices.of(context);
    final memo = TextEditingController();
    final ok = await showAppSheet<bool>(
      context,
      title: '이 정보가 다른가요?',
      initialSize: 0.46,
      maxSize: 0.7,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        children: [
          Text('"$regionName · ${tip.name}" 기준이 실제와 다르면 알려주세요. 같은 신고가 3건 모이면 이 안내를 내리고 구청 안내 링크로 바꿔요.', style: ctx.text.bodyMedium),
          const SizedBox(height: AppSpacing.base),
          TextField(controller: memo, maxLength: 120, maxLines: 2, decoration: const InputDecoration(hintText: '어떻게 다른가요? (선택)', counterText: '')),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('보내기')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await services.feedback.reportRegionNote(code: regionCode, tipId: tip.id, itemName: tip.name, note: note.note, memo: memo.text);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('고마워요. 확인해서 고칠게요.')));
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.tip, required this.regionName, required this.guideUrl, required this.compact});

  final Tip tip;
  final String? regionName;
  final String? guideUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final body = regionName == null
        ? '지자체별로 다를 수 있어요. 거주 지역을 설정하면 구청 안내로 바로 연결해 드려요.'
        : '지자체별로 다를 수 있어요. $regionName청 안내를 확인해 주세요.';
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.base),
      decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.location_on_rounded, size: 20, color: c.warningText),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('지자체별로 다를 수 있어요', style: t.titleSmall?.copyWith(color: c.warningText)),
                const SizedBox(height: AppSpacing.xs),
                Text(tip.hasLocalNote ? '${tip.localNote} ${regionName == null ? '' : '$regionName청 안내를 확인해 주세요.'}'.trim() : body, style: t.bodyMedium?.copyWith(color: c.warningText)),
                const SizedBox(height: AppSpacing.sm),
                if (guideUrl != null)
                  _LinkText(label: '$regionName청 분리배출 안내', icon: Symbols.open_in_new_rounded, color: c.warningText, onTap: () => ExternalLinks.open(guideUrl!))
                else if (regionName == null)
                  _LinkText(label: '거주 지역 설정', icon: Symbols.edit_location_alt_rounded, color: c.warningText, onTap: () => showRegionPickerSheet(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText({required this.label, required this.icon, this.onTap, this.color, this.muted = false});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final col = color ?? (muted ? c.textSecondary : c.primary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: col),
          const SizedBox(width: 4),
          Text(label, style: context.text.labelLarge?.copyWith(color: col, fontSize: 12.5)),
        ],
      ),
    );
  }
}
