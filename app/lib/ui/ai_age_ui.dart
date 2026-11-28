// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The one-time "만 18세 이상이에요" question before Android's Google AI
// (core/ai_age.dart), and the settings row to answer it again.
import 'package:flutter/cupertino.dart';

import '../core/ai_age.dart';
import '../core/app_state.dart';
import '../l10n/app_localizations.dart';
import 'ios.dart';
import 'translate_ui.dart' show trNotice;
import 'wide.dart';

/// True when the AI may run now. On Android asks once (an iOS action
/// sheet); under 18 shows "18세 이상만 쓸 수 있어요" and says no.
Future<bool> aiAgeOk(BuildContext context) async {
  final s = AppScope.read(context);
  if (AiAge.allowed(s)) return true;
  final l = L.of(context);
  if (AiAge.answer(s) == AiAgeAnswer.minor) {
    trNotice(context, l.aiAgeOnly);
    return false;
  }
  final adult = await askAiAge(context);
  if (adult == null || !context.mounted) return false;
  await AiAge.set(s, adult);
  if (!adult && context.mounted) trNotice(context, l.aiAgeOnly);
  return adult;
}

/// The question itself: true = 18 or older, false = under 18, null = closed.
Future<bool?> askAiAge(BuildContext context) {
  final l = L.of(context);
  return showCupertinoModalPopup<bool>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) => IosActionSheet(
      key: const Key('ai-age-sheet'),
      title: Text(l.aiAgeTitle),
      message: Text(l.aiAgeInfo),
      actions: [
        CupertinoActionSheetAction(key: const Key('ai-age-adult'), onPressed: () => Navigator.pop(c, true), child: Text(l.aiAgeAdult)),
        CupertinoActionSheetAction(key: const Key('ai-age-minor'), onPressed: () => Navigator.pop(c, false), child: Text(l.aiAgeMinor)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

/// Settings value text for the row.
String aiAgeValue(BuildContext context, AppState s) {
  final l = L.of(context);
  return switch (AiAge.answer(s)) {
    AiAgeAnswer.adult => l.aiAgeValueAdult,
    AiAgeAnswer.minor => l.aiAgeValueMinor,
    AiAgeAnswer.unknown => l.aiAgeValueUnknown,
  };
}
