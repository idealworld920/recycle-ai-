import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_services.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'external_links.dart';
import 'region.dart';
import 'region_picker_sheet.dart';

/// 팁 탭 상단 "버리는 곳" 카드 3개: 대형폐기물 신고 / 폐의약품 수거함 / 아이스팩·폐건전지 수거처.
class PlacesSection extends StatelessWidget {
  const PlacesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).region;
    final t = context.text;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final region = store.selected;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('버리는 곳', style: t.titleMedium)),
                TextButton.icon(
                  onPressed: () => showRegionPickerSheet(context),
                  icon: const Icon(Symbols.location_on_rounded, size: 18),
                  label: Text(region?.name ?? '지역 선택'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlaceCard(
              icon: Symbols.weekend_rounded,
              title: '대형폐기물 신고',
              subtitle: region == null ? '지역을 고르면 신고 페이지로 바로 연결돼요' : '${region.name} 신고 페이지 열기',
              onTap: () => _openBulky(context, region),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlaceCard(
              icon: Symbols.medication_rounded,
              title: '폐의약품 수거함',
              subtitle: '약국·보건소·주민센터에 비치. 가까운 약국 찾기',
              onTap: () => _openMedicine(context, region),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlaceCard(
              icon: Symbols.battery_charging_full_rounded,
              title: '아이스팩 · 폐건전지 수거처',
              subtitle: '주민센터 수거함, 지자체 안내 보기',
              onTap: () => _openBattery(context, region),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }

  Future<void> _openBulky(BuildContext context, Region? region) async {
    if (region == null) {
      await showRegionPickerSheet(context);
      return;
    }
    await showAppSheet(
      context,
      title: '대형폐기물 신고 · ${region.name}',
      initialSize: 0.5,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Text('가구·가전처럼 큰 물건은 지자체에 신고하고 스티커(필증)를 붙여 지정일에 내놓아요. 신고는 홈페이지나 주민센터에서 해요.', style: ctx.text.bodyMedium),
          if (region.note.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text(region.note, style: ctx.text.bodySmall)],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => ExternalLinks.open(region.bulkySearchUrl),
            icon: const Icon(Symbols.open_in_new_rounded, size: 20),
            label: const Text('신고 페이지 찾기'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => ExternalLinks.open(region.siteUrl),
            icon: const Icon(Symbols.language_rounded, size: 20),
            label: Text('${region.sigungu} 홈페이지'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('지자체 페이지 주소가 자주 바뀌어서 검색 결과로 연결해요. 대형 가전(냉장고·세탁기·TV)은 폐가전 무상방문수거 1599-0903 이 무료예요.', style: ctx.text.bodySmall),
        ],
      ),
    );
  }

  Future<void> _openMedicine(BuildContext context, Region? region) async {
    await showAppSheet(
      context,
      title: '폐의약품 수거함',
      initialSize: 0.5,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Text('먹다 남은 약은 약국·보건소·주민센터의 폐의약품 수거함에 넣어요. 포장은 분리하고 알약·물약만 모아서요. 변기나 하수구에는 절대 버리지 않아요.', style: ctx.text.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('일부 지역은 우체통 배출도 가능해요 (전용 봉투 필요). 거주 지역 확인이 필요해요.', style: ctx.text.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => ExternalLinks.openNearbyPharmacy(area: region?.name),
            icon: const Icon(Symbols.map_rounded, size: 20),
            label: Text(region == null ? '가까운 약국 지도에서 찾기' : '${region.name} 약국 지도에서 찾기'),
          ),
        ],
      ),
    );
  }

  Future<void> _openBattery(BuildContext context, Region? region) async {
    await showAppSheet(
      context,
      title: '아이스팩 · 폐건전지 수거처',
      initialSize: 0.55,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Text('폐건전지·보조배터리·형광등은 주민센터와 아파트 단지의 전용 수거함에 넣어요. 종량제 봉투에 넣으면 화재 위험이 있어요.', style: ctx.text.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('아이스팩은 기본은 종량제 봉투예요. 아이스팩 수거함을 운영하는 지자체도 있으니 아래에서 확인해 보세요.', style: ctx.text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          if (region == null)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                showRegionPickerSheet(context);
              },
              icon: const Icon(Symbols.location_on_rounded, size: 20),
              label: const Text('지역 선택하고 안내 보기'),
            )
          else ...[
            FilledButton.icon(
              onPressed: () => ExternalLinks.open(region.batterySearchUrl),
              icon: const Icon(Symbols.open_in_new_rounded, size: 20),
              label: Text('${region.sigungu} 수거함 안내 찾기'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => ExternalLinks.open(region.siteUrl),
              icon: const Icon(Symbols.language_rounded, size: 20),
              label: Text('${region.sigungu} 홈페이지'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Icon(icon, size: 24, color: c.textPrimary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
              ],
            ),
          ),
          Icon(Symbols.chevron_right_rounded, color: c.textSecondary),
        ],
      ),
    );
  }
}
