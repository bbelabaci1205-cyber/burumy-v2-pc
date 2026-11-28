// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat list: up to three small pictures before the last message when the
// newest messages are photos or videos sent together (Telegram tip 59).
// Hold them and they fan out above the row, larger; let go and they fly
// back into place.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import 'profile_page.dart' show SharedThumb;

/// Small picture size in the row, the gap between them, and the fanned
/// card size (Telegram iOS proportions at 393 pt).
const listThumb = 20.0, _gap = 2.0, _card = 96.0;

/// The newest photos/videos one person sent together (at most 3, oldest
/// first): each within two minutes of the next, nothing else between.
List<Msg> mediaRun(List<Msg> timeline) {
  final run = <Msg>[];
  for (final m in timeline.reversed) {
    final media = (m.kind == 'image' || m.kind == 'video') && !m.viewOnce;
    if (!media) break;
    if (run.isNotEmpty && (m.sender != run.last.sender || run.last.time.difference(m.time).abs() > const Duration(minutes: 2))) break;
    run.add(m);
    if (run.length == 3) break;
  }
  return run.reversed.toList();
}

class ListThumbs extends StatefulWidget {
  const ListThumbs({super.key, required this.roomId, required this.last});
  final String roomId;
  final Msg last;

  static final _cache = <String, Future<List<Msg>>>{};

  @override
  State<ListThumbs> createState() => _ListThumbsState();
}

class _ListThumbsState extends State<ListThumbs> with SingleTickerProviderStateMixin {
  late final fan = AnimationController(vsync: this, duration: const Duration(milliseconds: 280), reverseDuration: const Duration(milliseconds: 200));
  Future<List<Msg>>? run;
  OverlayEntry? entry;
  final key = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = AppScope.of(context).backend;
    final k = '${widget.roomId}|${widget.last.id}';
    run = ListThumbs._cache[k] ??= b.timeline(widget.roomId, limit: 8).then(mediaRun, onError: (_) => [widget.last]);
  }

  @override
  void dispose() {
    entry?.remove();
    fan.dispose();
    super.dispose();
  }

  void open(List<Msg> msgs) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || entry != null) return;
    HapticFeedback.mediumImpact();
    final origin = box.localToGlobal(Offset.zero);
    final calm = AppScope.read(context).calm;
    entry = OverlayEntry(
      builder: (c) => _Fan(anim: fan, origin: origin, roomId: widget.roomId, msgs: msgs),
    );
    Overlay.of(context, rootOverlay: true).insert(entry!);
    calm ? fan.value = 1 : fan.forward(from: 0);
  }

  Future<void> close() async {
    if (entry == null) return;
    if (!AppScope.read(context).calm) await fan.reverse();
    entry?.remove();
    entry = null;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Msg>>(
    future: run,
    initialData: [widget.last],
    builder: (_, snap) {
      final msgs = snap.data!.isEmpty ? [widget.last] : snap.data!;
      return GestureDetector(
        key: const Key('list-thumb'),
        onLongPressStart: (_) => open(msgs),
        onLongPressEnd: (_) => unawaited(close()),
        onLongPressCancel: () => unawaited(close()),
        child: Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < msgs.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : _gap),
                child: SizedBox(
                  key: Key('list-thumb-$i'),
                  width: listThumb,
                  height: listThumb,
                  child: SharedThumb(roomId: widget.roomId, msg: msgs[i]),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// The pictures grown and spread like a hand of cards above the row.
class _Fan extends StatelessWidget {
  const _Fan({required this.anim, required this.origin, required this.roomId, required this.msgs});
  final Animation<double> anim;
  final Offset origin;
  final String roomId;
  final List<Msg> msgs;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final n = msgs.length;
    final grow = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: grow,
        builder: (_, _) {
          final t = grow.value;
          // Centre of the fan: over the thumbs, kept on screen.
          final cx = (origin.dx + _card).clamp(_card, w - _card);
          final cy = origin.dy - _card / 2 - Tokens.space[2];
          return Stack(
            children: [
              for (var i = 0; i < n; i++)
                () {
                  final k = n == 1 ? 0.0 : i - (n - 1) / 2;
                  final from = Offset(origin.dx + i * (listThumb + _gap) + listThumb / 2, origin.dy + listThumb / 2);
                  final to = Offset(cx + k * _card * 0.62, cy + k.abs() * Tokens.space[1]);
                  final at = Offset.lerp(from, to, t)!;
                  final size = listThumb + (_card - listThumb) * t;
                  return Positioned(
                    left: at.dx - size / 2,
                    top: at.dy - size / 2,
                    child: Transform.rotate(
                      angle: k * 9 * math.pi / 180 * t,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4 + 8 * t),
                          // iOS lift: a soft shadow, no border.
                          boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.22 * t.clamp(0, 1)), blurRadius: 18 * t, offset: Offset(0, 6 * t))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SharedThumb(roomId: roomId, msg: msgs[i]),
                      ),
                    ),
                  );
                }(),
            ],
          );
        },
      ),
    );
  }
}
