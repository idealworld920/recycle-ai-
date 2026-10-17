import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/theme/app_theme.dart';
import 'paywall_screen.dart';

/// 프리미엄이면 true. 아니면 페이월을 띄우고 결제 결과를 돌려준다.
Future<bool> ensurePremium(BuildContext context, {String? reason}) async {
  final premium = AppServices.of(context).premium;
  if (premium.isPremium) return true;
  final ok = await context.pushPage<bool>(PaywallScreen(reason: reason));
  return ok == true || premium.isPremium;
}
