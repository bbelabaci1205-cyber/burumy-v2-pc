// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 버그·제안 보내기 (Telegram tip 546, Eric 2026-11-27 option B "간단판"):
// one form in Settings. It goes as an ordinary end-to-end encrypted 1:1
// message to the official support account, so only the team reads it
// (Telegram's @bugs board is public). Only the kind, the words, the
// device type and the app version go, plus the error log if the person
// turns it on; never chats, contacts or files. What was sent is listed
// on this phone only. Fixes are posted in the official news channel.
// Option A (public board with votes and status) can grow from this later.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../brand/brand.dart';
import '../core/app_state.dart';
import '../core/error_log.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'settings_kit.dart';

/// The support account on the same server as me.
String supportIdFor(String? me) {
  final server = (me ?? '').contains(':') ? me!.substring(me.indexOf(':') + 1) : 'burumy.app';
  return '@${Brand.supportLocalpart}:$server';
}

String deviceKind() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.android => 'Android',
    TargetPlatform.windows => 'Windows',
    TargetPlatform.macOS => 'macOS',
    _ => 'Linux',
  };
}

/// The message the team gets (plain words, easy to read in any app).
String feedbackText({required bool bug, required String title, required String body, required String device, List<String> errors = const []}) {
  final b = StringBuffer()
    ..writeln(bug ? '[BUG] $title' : '[IDEA] $title')
    ..writeln()
    ..writeln(body.trim())
    ..writeln()
    ..writeln('— ${Brand.nameEn} v2 · $device');
  if (errors.isNotEmpty) {
    b
      ..writeln()
      ..writeln('Error log (${errors.length})');
    for (final e in errors.take(10)) {
      b.writeln('• $e');
    }
  }
  return b.toString().trim();
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  bool bug = true;
  bool attachLog = false;
  bool sending = false;
  bool tried = false;
  final title = TextEditingController();
  final body = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> sent(AppState s) {
    try {
      return [for (final j in jsonDecode(s.pref('feedback_sent', '[]')) as List) (j as Map).cast<String, dynamic>()];
    } catch (_) {
      return [];
    }
  }

  Future<void> send() async {
    final s = AppScope.read(context);
    final l = L.of(context);
    if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
      setState(() => tried = true);
      return;
    }
    setState(() => sending = true);
    try {
      final text = feedbackText(
        bug: bug,
        title: title.text.trim(),
        body: body.text,
        device: deviceKind(),
        errors: attachLog ? [for (final (_, e) in ErrorLog.items) e.split('\n').first] : const [],
      );
      final room = await s.backend.createDirectChat(supportIdFor(s.backend.userId));
      await s.backend.sendText(room, text);
      final list = sent(s)..insert(0, {'bug': bug, 'title': title.text.trim(), 'at': DateTime.now().millisecondsSinceEpoch});
      await s.setPref('feedback_sent', jsonEncode(list.take(30).toList()));
      if (!mounted) return;
      title.clear();
      body.clear();
      setState(() {
        sending = false;
        tried = false;
        attachLog = false;
      });
      await showCupertinoDialog<void>(
        context: context,
        builder: (x) => CupertinoAlertDialog(
          title: Text(l.feedbackSentTitle),
          content: Text(l.feedbackSentBody),
          actions: [CupertinoDialogAction(key: const Key('feedback-ok'), onPressed: () => Navigator.pop(x), child: Text(l.okButton))],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => sending = false);
      await showCupertinoDialog<void>(
        context: context,
        builder: (x) => CupertinoAlertDialog(
          title: Text(l.feedbackFailed),
          actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(x), child: Text(l.okButton))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final mine = sent(s);
    final errors = ErrorLog.items.length;
    final fmt = DateFormatShort(l);
    Widget field(Key key, TextEditingController c, String hint, {int lines = 1, int max = 80}) => CupertinoTextField(
      key: key,
      controller: c,
      placeholder: hint,
      minLines: lines,
      maxLines: lines == 1 ? 1 : 12,
      maxLength: max,
      decoration: null,
      onChanged: (_) => setState(() {}),
      style: Tokens.body.style.copyWith(color: p.label),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
    );
    final missing = tried && (title.text.trim().isEmpty || body.text.trim().isEmpty);
    return SettingsScaffold(
      title: l.feedbackTitle,
      trailing: [
        sending ? const Padding(padding: EdgeInsets.all(12), child: CupertinoActivityIndicator()) : GlassDone(key: const Key('feedback-send'), onTap: send),
      ],
      children: [
        HeaderCard(color: Palette.tilePurple, icon: CupertinoIcons.ant_fill, title: l.feedbackTitle, body: l.feedbackHeader),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], 0),
          child: IosSegmented<bool>(
            key: const Key('feedback-kind'),
            groupValue: bug,
            onValueChanged: (v) => setState(() => bug = v ?? true),
            children: {true: Text(l.feedbackBug), false: Text(l.feedbackIdea)},
          ),
        ),
        group(context, header: l.feedbackWhat, footer: missing ? l.feedbackNeedWords : (bug ? l.feedbackBugHint : l.feedbackIdeaHint), error: missing, [
          field(const Key('feedback-subject'), title, l.feedbackSubject),
          field(const Key('feedback-body'), body, bug ? l.feedbackBodyBug : l.feedbackBodyIdea, lines: 5, max: 2000),
        ]),
        group(context, footer: l.feedbackPrivacy(deviceKind()), [
          if (errors > 0)
            IosTile(
              key: const Key('feedback-log'),
              title: Text(l.feedbackAttachLog(errors)),
              trailing: IosSwitch(value: attachLog, onChanged: (v) => setState(() => attachLog = v)),
            ),
          IosTile(
            title: Text(l.feedbackGoesTo),
            trailing: Text(l.feedbackTeam, style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
          ),
        ]),
        if (mine.isNotEmpty)
          group(context, header: l.feedbackMine, footer: l.feedbackMineInfo, [
            for (final f in mine.take(10))
              IosTile(
                title: Text('${f['bug'] == true ? '🐞' : '💡'}  ${f['title']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  fmt.of(DateTime.fromMillisecondsSinceEpoch((f['at'] as num).toInt())),
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                ),
              ),
          ]),
      ],
    );
  }
}

/// "11월 27일" style date (no package needed here).
class DateFormatShort {
  const DateFormatShort(this.l);
  final L l;
  String of(DateTime t) => l.feedbackDate(t.month, t.day);
}
