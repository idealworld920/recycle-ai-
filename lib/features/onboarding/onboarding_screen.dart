import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/mascot.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'account_page.dart';
import 'consent_sheet.dart';
import '../splash/splash_plan.dart';
import '../splash/splash_screen.dart';
import 'pages.dart';
import '../../core/analytics.dart';

/// 최초 실행 온보딩: 핵심 가치 → 루틴 → 동의 → 계정 선택(Google / 나중에). (인트로 애니메이션은 스플래시가 맡는다)
///
/// [replay] 면 설정의 "온보딩 다시 보기": 스플래시 풀 버전 → 1 → 2 를 본 뒤 [onDone]. 동의는 묻지 않는다.
/// Firebase 익명 로그인은 백그라운드에서 따로 돌고, 이 화면은 그걸 기다리지 않는다.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone, this.replay = false});

  final VoidCallback onDone;
  final bool replay;

  static const pageDuration = Duration(milliseconds: 200);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _controller = PageController();
  final _consent = ConsentController();
  late final AnimationController _introSlide = AnimationController(vsync: this, duration: OnboardingScreen.pageDuration);
  late bool _intro = widget.replay;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.replay) {
      Analytics.log('onboarding_start');
      _logPage(0);
    }
  }

  /// onboarding_page_view {page: 1|2|3|account}
  void _logPage(int i) {
    if (widget.replay) return;
    Analytics.log('onboarding_page_view', {'page': i == _lastIndex ? 'account' : '${i + 1}'});
  }

  int get _pageCount => widget.replay ? 2 : 4;
  int get _lastIndex => _pageCount - 1;
  int get _consentIndex => 2;
  bool get _onConsent => !widget.replay && _page == _consentIndex;
  bool get _onAccount => !widget.replay && _page == _lastIndex;

  @override
  void dispose() {
    _controller.dispose();
    _consent.dispose();
    _introSlide.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  Future<void> _leaveIntro() async {
    if (!_intro) return;
    if (!_reduceMotion) await _introSlide.forward();
    if (mounted) setState(() => _intro = false);
  }

  void _goTo(int index) {
    if (_reduceMotion) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(index, duration: OnboardingScreen.pageDuration, curve: Curves.easeOut);
    }
  }

  Future<void> _next() async {
    if (widget.replay) {
      if (_page < _lastIndex) {
        _goTo(_page + 1);
      } else {
        widget.onDone();
      }
      return;
    }
    if (_page < _consentIndex) {
      _goTo(_page + 1);
      return;
    }
    if (_onConsent) {
      // 동의 저장(onboardingDone 포함) 뒤 계정 선택으로. 계정 페이지는 자기 버튼으로 끝낸다.
      await _consent.submit(AppServices.of(context));
      if (mounted) _goTo(_lastIndex);
    }
  }

  void _skip() {
    if (widget.replay) {
      widget.onDone();
    } else {
      Analytics.log('onboarding_skip', {'page': _page + 1});
      _goTo(_consentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showSkip = !_intro && !_onConsent && !_onAccount;
    return PopScope(
      // 동의 페이지(또는 2페이지 이후)에서 뒤로가기는 앞 페이지로. 1페이지에서는 평소대로.
      // 계정 선택 페이지는 동의가 이미 저장된 뒤라 뒤로 가지 않는다 (Google / 나중에 중 하나로 끝낸다).
      canPop: _intro || _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0 && !_onAccount) _goTo(_page - 1);
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: showSkip
                          ? TextButton(
                              style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                              onPressed: _skip,
                              child: const Text('건너뛰기'),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      // 동의·계정 페이지에서는 스와이프로 못 움직이게 (버튼으로만).
                      physics: (_onConsent || _onAccount) ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
                      onPageChanged: (i) {
                        setState(() => _page = i);
                        _logPage(i);
                      },
                      children: [
                        const OnboardingValuePage(
                          mock: ResultMock(),
                          mascot: Mascot.wink,
                          bubble: '뭐든 가져와뿅! 리뿅이가 알려주겠뿅!',
                          title: '찍으면 바로 알려줘요',
                          subtitle: '쓰레기 사진 한 장이면 어디에 버릴지, 뭘 떼야 하는지 바로 알 수 있어요',
                        ),
                        const OnboardingValuePage(
                          mock: RoutineMock(),
                          mascot: Mascot.happy,
                          bubble: '매주 수거일도 챙겨주겠뿅!',
                          title: '수거일도 알려드려요',
                          subtitle: '전날 저녁에 알려주고, 홈 화면 위젯으로 D-day까지 보여드려요',
                          caption: '가족이랑 같이 쓰면 누가 버렸는지도 알 수 있어요',
                        ),
                        if (!widget.replay) ConsentPage(controller: _consent),
                        if (!widget.replay) AccountPage(onDone: widget.onDone),
                      ],
                    ),
                  ),
                  _Dots(count: _pageCount, index: _page),
                  const SizedBox(height: AppSpacing.base),
                  if (!_onAccount)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.base),
                      child: ListenableBuilder(
                        listenable: _consent,
                        builder: (context, _) => FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: c.ink,
                            foregroundColor: c.onInk,
                            disabledBackgroundColor: c.textDisabled,
                            disabledForegroundColor: c.onInk,
                          ),
                          // 동의 페이지: 필수 2개 체크 전엔 비활성.
                          onPressed: _onConsent && !_consent.canStart ? null : _next,
                          child: Text(_onConsent ? (_consent.saving ? '저장하는 중…' : '시작하기') : (widget.replay && _page == _lastIndex ? '홈으로' : '다음')),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_intro)
              SlideTransition(
                position: Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0)).animate(CurvedAnimation(parent: _introSlide, curve: Curves.easeOut)),
                child: SplashScreen(plan: const SplashPlan(SplashKind.firstRun), ready: Future.value(), onDone: (_) => _leaveIntro()),
              ),
          ],
        ),
      ),
    );
  }
}

/// 하단 점 인디케이터. 인트로에서는 보이지 않는다(인트로가 위를 덮는다).
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: OnboardingScreen.pageDuration,
            curve: Curves.easeOut,
            width: i == index ? 20 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(color: i == index ? c.ink : c.divider, borderRadius: BorderRadius.circular(AppRadius.chip)),
          ),
      ],
    );
  }
}
