import 'dart:math';

import 'package:flutter/material.dart';

import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

/// 리뿅이. 결과·대기·피드백·온보딩·홈 화면에 나오고 설정·약관·결제 화면엔 등장하지 않는다.
///
/// GIF 가 기본이고, 시스템 "애니메이션 줄이기" 가 켜져 있거나 [animated] 가 false 면
/// 첫 프레임 PNG(`r_*_static.png`)를 쓴다. 공유 카드·알림은 항상 PNG.
/// 표정마다 GIF 와 정지 PNG 가 모두 있다 (`tool/mascot_frames.py` 로 생성).
enum Mascot {
  happy('r_happy'),
  cheer('r_cheer'),
  laugh('r_laugh'),
  thinking('r_thinking'),
  /// 윙크. 온보딩 1페이지·첫 카메라 힌트·분류 성공.
  wink('r_wink'),
  /// 온보딩 인트로: 쓰레기통 뚜껑이 열리는 2초. 정지 이미지는 마지막 프레임.
  intro('r_intro'),
  /// 갸웃. 분류 실패·검색 결과 없음.
  confused('r_confused'),
  /// 울상. 데이터 삭제 확인.
  crying('r_crying'),
  /// 가만히 있는 리뿅이. 홈 상주.
  idle('r_idle');

  const Mascot(this._base);

  final String _base;

  String get gif => 'assets/branding/mascot/$_base.gif';
  String get png => 'assets/branding/mascot/${_base}_static.png';

  /// 축하·탭 반응에 랜덤으로 쓰는 happy 계열.
  static const happyFamily = [happy, cheer, laugh];
  static Mascot randomHappy([Random? rnd]) => happyFamily[(rnd ?? Random()).nextInt(happyFamily.length)];
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
    final blank = SizedBox(width: size, height: size);
    // GIF 디코딩이 실패하면 같은 표정의 정지 PNG 로 (다른 표정으로 바꾸지 않는다).
    if (!useGif) return _asset(mascot.png, onError: () => blank);
    return _asset(mascot.gif, onError: () => _asset(mascot.png, onError: () => blank));
  }

  Widget _asset(String path, {required Widget Function() onError}) => Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => onError(),
      );
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

/// 빈 화면·로딩·네트워크 끊김·검색 결과 없음 공통: 리뿅이 + 한 줄.
class MascotEmpty extends StatelessWidget {
  const MascotEmpty({super.key, required this.text, this.mascot = Mascot.confused, this.size = 72, this.action});

  final Mascot mascot;
  final String text;
  final double size;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotImage(mascot, size: size),
          const SizedBox(height: AppSpacing.md),
          Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.textSecondary), textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: AppSpacing.base), action!],
        ],
      ),
    );
  }
}
