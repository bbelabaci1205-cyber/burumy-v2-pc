// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 대화 안전 묶음 (Telegram tips 557, 478, 418; Eric 2026-11-27 "다해죠"),
// behind Features.chatSafety:
// - 557 공유 비활성화: intro sheet before turning it on, a notice pill
//   above the composer, and only the person who turned it on (1:1) can
//   turn it off.
// - 478 자세한 신고: reason → narrower reason → optional note.
// - 418 한 번만 듣기: the voice bubble that opens once, and its player.
// Our own layout (iOS 27 sheets and pills), Telegram only as a reference
// for what the feature does.
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../brand/brand.dart';
import '../core/app_state.dart';
import '../core/report_reasons.dart';
import '../core/screen_guard.dart';
import '../core/voice.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'message_sheets.dart';
import 'wide.dart';

// ---- 557 공유 비활성화 -------------------------------------------------

/// Who may turn 공유 비활성화 off. In a 1:1 both people are admins of the
/// room, so the app keeps who turned it on ('protect_by') and only that
/// person gets the off switch (Telegram: the one who disabled sharing).
/// Groups and channels: admins, as before.
bool mayTurnProtectOff(Map<String, dynamic> cfg, {required bool direct, required String me}) {
  if (cfg['protect'] != true) return true;
  final by = cfg['protect_by'];
  if (!direct || by is! String || by.isEmpty) return true;
  return by == me;
}

/// The intro before it is turned on: what it blocks, then one button.
/// Returns true when the person turned it on.
Future<bool> showProtectIntro(BuildContext context, {required bool direct}) async {
  final ok = await showCupertinoModalPopup<bool>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) {
      final l = L.of(c);
      final p = paletteOf(c);
      Widget row(IconData icon, String title, String sub) => Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[4], vertical: Tokens.space[1]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, size: Tokens.listIconSmall, color: p.accent),
            ),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Tokens.body.style.copyWith(color: p.label)),
                  Text(sub, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                ],
              ),
            ),
          ],
        ),
      );
      return GlassSheet(
        key: const Key('protect-intro'),
        children: [
          SizedBox(height: Tokens.space[2]),
          Icon(CupertinoIcons.hand_raised_fill, size: 44, color: p.accent),
          SizedBox(height: Tokens.space[2]),
          Text(
            l.protect,
            textAlign: TextAlign.center,
            style: Tokens.cardTitle.style.copyWith(color: p.label),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], Tokens.space[2]),
            child: Text(
              direct ? l.protectIntroInfoDm : l.protectIntroInfoRoom,
              textAlign: TextAlign.center,
              style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
            ),
          ),
          row(CupertinoIcons.camera_viewfinder, l.protectIntroShot, l.protectIntroShotSub),
          row(CupertinoIcons.arrowshape_turn_up_right, l.protectIntroForward, l.protectIntroForwardSub),
          row(CupertinoIcons.square_arrow_down, l.protectIntroSave, l.protectIntroSaveSub),
          if (direct)
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], 0),
              child: Text(
                l.protectIntroOnlyMe,
                textAlign: TextAlign.center,
                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(Tokens.space[3]),
            child: AccentButton(key: const Key('protect-intro-go'), text: l.protectOn, onTap: () => Navigator.pop(c, true)),
          ),
        ],
      );
    },
  );
  return ok == true;
}

/// Small glass pill above the composer: who turned sharing off here.
class ProtectNotice extends StatelessWidget {
  const ProtectNotice({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: Tokens.space[1]),
      child: Center(
        child: GestureDetector(
          key: const Key('protect-notice'),
          onTap: onTap,
          child: LiquidGlass(
            radius: Tokens.capsule,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1] - 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.hand_raised_fill, size: 14, color: p.secondaryLabel),
                  SizedBox(width: Tokens.space[0] + 2),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- 478 자세한 신고 ---------------------------------------------------

String reportLabel(L l, String code) => switch (code) {
  ReportReasons.dislike => l.rDislike,
  'child' => l.rChild,
  'child.sexual' => l.rChildSexual,
  'child.abuse' => l.rChildAbuse,
  'child.danger' => l.rChildDanger,
  'sexual_crime' => l.rSexualCrime,
  'sexual_crime.hidden_camera' => l.rHiddenCamera,
  'sexual_crime.deepfake' => l.rDeepfake,
  'sexual_crime.shared_without_consent' => l.rSharedNoConsent,
  'sexual_crime.extortion' => l.rExtortion,
  'violence' => l.rViolence,
  'violence.threat' => l.rThreat,
  'violence.graphic' => l.rGraphic,
  'violence.self_harm' => l.rSelfHarm,
  'violence.hate' => l.rHate,
  'goods' => l.rGoods,
  'goods.drugs' => l.rDrugs,
  'goods.weapons' => l.rWeapons,
  'goods.fake_documents' => l.rFakeDocs,
  'goods.other' => l.rGoodsOther,
  'adult' => l.rAdult,
  'adult.porn' => l.rPorn,
  'adult.unwanted' => l.rUnwanted,
  'privacy' => l.rPrivacy,
  'privacy.id_documents' => l.rIdDocs,
  'privacy.contact' => l.rContact,
  'privacy.photos' => l.rPhotos,
  'terror' => l.rTerror,
  'terror.promotion' => l.rTerrorPromo,
  'terror.recruiting' => l.rTerrorRecruit,
  'scam' => l.rScam,
  'scam.phishing' => l.rPhishing,
  'scam.money' => l.rMoney,
  'scam.spam' => l.rSpam,
  ReportReasons.impersonation => l.reportImpersonation,
  ReportReasons.copyright => l.rCopyright,
  'takedown' => l.rTakedown,
  _ => l.reportOther,
};

/// What the reporter chose. [code] is one of [ReportReasons]; for
/// "dislike" [dislike] says what to do on this phone ('hide' / 'block').
class ReportPick {
  const ReportPick(this.code, {this.note = '', this.dislike});
  final String code;
  final String note;
  final String? dislike;
}

/// The report sheet: step 1 reasons, step 2 narrower reasons, step 3 a
/// note and the send button. Special picks return at once (impersonation)
/// or show their own page (dislike, copyright).
Future<ReportPick?> showReportSheet(BuildContext context) =>
    showCupertinoModalPopup<ReportPick>(useRootNavigator: !Wide.on, context: context, builder: (_) => const _ReportSheet());

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? group;
  String? chosen;
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void pick(ReportReason r) {
    if (r.code == ReportReasons.impersonation) {
      Navigator.pop(context, const ReportPick(ReportReasons.impersonation));
      return;
    }
    setState(() {
      if (r.subs.isNotEmpty) {
        group = r;
      } else {
        chosen = r.code;
      }
    });
  }

  void back() => setState(() => chosen != null ? chosen = null : group = null);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final c = chosen;
    final List<Widget> body;
    String title;
    if (c == null) {
      title = group == null ? l.reportStepTitle : reportLabel(l, group!.code);
      final list = group?.subs ?? ReportReasons.all;
      body = [
        if (group == null)
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
            child: Text(l.reportNote, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
          )
        else
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
            child: Text(l.reportSubTitle, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
          ),
        for (final r in list) SheetRow(key: Key('report-${r.code}'), label: reportLabel(l, r.code), chevron: r.subs.isNotEmpty, onTap: () => pick(r)),
      ];
    } else if (c == ReportReasons.dislike) {
      title = l.rDislike;
      body = [
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
          child: Text(l.reportDislikeInfo, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
        ),
        SheetRow(
          key: const Key('report-dislike-hide'),
          label: l.reportDislikeHide,
          onTap: () => Navigator.pop(context, const ReportPick(ReportReasons.dislike, dislike: 'hide')),
        ),
        SheetRow(
          key: const Key('report-dislike-block'),
          label: l.reportDislikeBlock,
          onTap: () => Navigator.pop(context, const ReportPick(ReportReasons.dislike, dislike: 'block')),
        ),
      ];
    } else if (c == ReportReasons.copyright) {
      title = l.rCopyright;
      body = [
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[2]),
          child: Text(l.reportCopyrightInfo, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: AccentButton(
            key: const Key('report-copyright-open'),
            text: l.reportCopyrightOpen,
            onTap: () {
              unawaited(launchUrl(Uri.https(Brand.linkHost, '/rights'), mode: LaunchMode.externalApplication).catchError((_) => false));
              Navigator.pop(context);
            },
          ),
        ),
      ];
    } else {
      title = reportLabel(l, c);
      body = [
        if (ReportReasons.urgent(c))
          Padding(
            key: const Key('report-urgent'),
            padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
            child: Row(
              children: [
                Icon(CupertinoIcons.exclamationmark_circle_fill, size: 16, color: Palette.tileRed),
                SizedBox(width: Tokens.space[1]),
                Expanded(
                  child: Text(l.reportUrgentLine, style: Tokens.preview.style.copyWith(color: Palette.tileRed)),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[0]),
          child: Text(l.reportNoteTitle, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: CupertinoTextField(
            key: const Key('report-note'),
            controller: note,
            placeholder: l.reportNoteHint,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            padding: EdgeInsets.all(Tokens.space[2]),
            style: Tokens.body.style.copyWith(color: p.label),
            decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(Tokens.space[3]),
          child: AccentButton(
            key: const Key('report-send'),
            text: l.reportSend,
            onTap: () => Navigator.pop(context, ReportPick(c, note: note.text)),
          ),
        ),
      ];
    }
    final canBack = group != null || c != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassSheet(
        key: const Key('report-sheet'),
        children: [
          SizedBox(
            height: 44,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    title,
                    key: const Key('report-title'),
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                  ),
                ),
                if (canBack)
                  Positioned(
                    left: Tokens.space[1],
                    top: 0,
                    bottom: 0,
                    child: CupertinoButton(
                      key: const Key('report-back'),
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                      onPressed: back,
                      child: Icon(CupertinoIcons.chevron_back, color: p.accent),
                    ),
                  ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
            ),
          ),
          SizedBox(height: Tokens.space[1]),
        ],
      ),
    );
  }
}

/// Messages I hid on this phone with "그냥 싫어요" (pref, per chat).
const hiddenMsgsPref = 'disliked:';

Set<String> dislikedIn(AppState s, String roomId) => s.pref('$hiddenMsgsPref$roomId', '').split(',').where((x) => x.isNotEmpty).toSet();

Future<void> hideDisliked(AppState s, String roomId, String eventId) => s.setPref('$hiddenMsgsPref$roomId', {...dislikedIn(s, roomId), eventId}.join(','));

// ---- 418 한 번만 듣기 음성 --------------------------------------------

/// Voice messages that open once travel as view-once audio; the length
/// rides in the (encrypted) file name, e.g. "voiceonce-12340.m4a".
const onceVoicePrefix = 'voiceonce-';

String onceVoiceName(Duration d, String mime) =>
    '$onceVoicePrefix${d.inMilliseconds}.${mime.contains('mp4') || mime.contains('m4a') || mime.contains('aac') ? 'm4a' : (mime.contains('ogg') || mime.contains('opus') ? 'ogg' : 'wav')}';

Duration? onceVoiceLength(String? body) {
  final b = body ?? '';
  if (!b.startsWith(onceVoicePrefix)) return null;
  final ms = int.tryParse(b.substring(onceVoicePrefix.length).split('.').first);
  return ms == null ? null : Duration(milliseconds: ms);
}

String _clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// The bubble of a 한 번만 듣기 voice message: a "1" play button, flat
/// dotted bars (nothing to read before it is opened), and the state line.
class OnceVoiceBubble extends StatelessWidget {
  const OnceVoiceBubble({super.key, required this.body, required this.mine, required this.opened, required this.fg, required this.meta, required this.onOpen});
  final String? body;
  final bool mine, opened;
  final Color fg;
  final Widget meta;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final len = onceVoiceLength(body);
    final canOpen = !mine && !opened;
    if (opened) {
      // Played: a grey pill instead of the bubble's contents.
      return Row(
        key: const Key('once-voice-expired'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.waveform, size: 18, color: fg.withValues(alpha: 0.6)),
          SizedBox(width: Tokens.space[1]),
          Text(l.onceVoiceExpired, style: Tokens.body.style.copyWith(color: fg.withValues(alpha: 0.7))),
          SizedBox(width: Tokens.space[1]),
          meta,
        ],
      );
    }
    return GestureDetector(
      key: const Key('once-voice'),
      behavior: HitTestBehavior.opaque,
      onTap: canOpen ? onOpen : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: mine ? p.onAccent : p.accent, shape: BoxShape.circle),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(CupertinoIcons.play_fill, color: mine ? p.accent : p.onAccent, size: 18),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: mine ? p.accent : p.onAccent, shape: BoxShape.circle),
                    child: Text('1', style: Tokens.bubbleMeta.style.copyWith(color: mine ? p.onAccent : p.accent, fontSize: 9, height: 1)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Tokens.space[1]),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 18; i++)
                        Container(
                          width: 2.5,
                          height: 2.5,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(color: fg.withValues(alpha: 0.45), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        [if (len != null) _clock(len), canOpen ? l.onceVoiceTap : l.onceVoiceSent].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.bubbleMeta.style.copyWith(color: fg.withValues(alpha: 0.7)),
                      ),
                    ),
                    SizedBox(width: Tokens.space[1]),
                    meta,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Plays a 한 번만 듣기 voice message over the blurred chat, then closes
/// by itself; "닫고 삭제" stops it early. The bytes are only in memory.
class OnceVoicePage extends StatefulWidget {
  const OnceVoicePage({super.key, required this.bytes, required this.length, this.autoplay = true});
  final Uint8List bytes;
  final Duration? length;
  final bool autoplay;

  @override
  State<OnceVoicePage> createState() => _OnceVoicePageState();
}

class _OnceVoicePageState extends State<OnceVoicePage> {
  VoicePlayer? player;
  Duration at = Duration.zero;
  bool started = false;
  final subs = <StreamSubscription<Object>>[];

  @override
  void initState() {
    super.initState();
    if (widget.autoplay) unawaited(start());
  }

  Future<void> start() async {
    final pl = VoiceKit.player();
    player = pl;
    subs.add(pl.position.listen((d) => mounted ? setState(() => at = d) : null));
    subs.add(
      pl.playing.listen((v) {
        if (v) started = true;
        // Finished: close (the message is already gone for good).
        if (!v && started && mounted) Navigator.of(context).maybePop();
      }),
    );
    try {
      await pl.play(widget.bytes, 'once-${widget.bytes.length}');
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final s in subs) {
      s.cancel();
    }
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final total = widget.length ?? Duration.zero;
    final done = total.inMilliseconds == 0 ? 0.0 : (at.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return CaptureBlock(
      what: 'voice',
      child: Stack(
        key: const Key('once-voice-page'),
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: ColoredBox(color: const Color(0xFF000000).withValues(alpha: 0.35)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                  child: Container(
                    padding: EdgeInsets.all(Tokens.space[2]),
                    decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[3])),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                          child: Icon(CupertinoIcons.waveform, color: p.onAccent, size: 20),
                        ),
                        SizedBox(width: Tokens.space[2]),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(Tokens.capsule),
                                child: SizedBox(
                                  height: 4,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(child: ColoredBox(color: p.label.withValues(alpha: 0.12))),
                                      FractionallySizedBox(
                                        widthFactor: done,
                                        child: ColoredBox(color: p.accent),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: Tokens.space[1]),
                              Text(
                                total == Duration.zero ? _clock(at) : '${_clock(at)} / ${_clock(total)}',
                                key: const Key('once-voice-time'),
                                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], 0),
                  child: Text(
                    l.onceVoiceInfo,
                    textAlign: TextAlign.center,
                    style: Tokens.caption.style.copyWith(color: const Color(0xE6FFFFFF)),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: Tokens.space[4]),
                  child: GlassPill(key: const Key('once-voice-close'), text: l.onceVoiceClose, onTap: () => Navigator.of(context).maybePop()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
