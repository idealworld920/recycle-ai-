import 'package:flutter/material.dart';

import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

/// 리뿅이. 결과·대기·피드백 화면에만 나오고 설정 화면엔 등장하지 않는다.
///
/// GIF 가 기본이고, 시스템 "애니메이션 줄이기" 가 켜져 있거나 [animated] 가 false 면
/// 첫 프레임 PNG(`r_*_static.png`)를 쓴다. 공유 카드·알림은 항상 PNG.
enum Mascot {
  happy('r_happy'),
  cheer('r_cheer'),
  thinking('r_thinking');

  const Mascot(this._base);

  final String _base;

  String get gif => 'assets/branding/mascot/$_base.gif';
  String get png => 'assets/branding/mascot/${_base}_static.png';
}

class MascotImage extends StatelessWidget {
  const MascotImage(this.mascot, {super.key, this.size = 96, this.animated = true});

  final Mascot mascot;
  final double size;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final useGif = animated && !reduceMotion;
    return Image.asset(
      useGif ? mascot.gif : mascot.png,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}

/// 리뿅이 + 말풍선 한 줄. 문장은 "~뿅" 으로 끝낸다.
class MascotSay extends StatelessWidget {
  const MascotSay({super.key, required this.mascot, required this.text, this.size = 72});

  final Mascot mascot;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MascotImage(mascot, size: size),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
            decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Text(text, style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
          ),
        ),
      ],
    );
  }
}
