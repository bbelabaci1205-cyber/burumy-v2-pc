// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Layout guard (Eric 2026-11-24): no left/right asymmetry, no uneven
// heights or widths. Walks the main screens at iPhone size and checks
// top-bar buttons, cards, rows, the tab bar and the composer.
import 'dart:async';
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/glass.dart';
import 'package:burumy/ui/ios.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show DebugCreator;
import 'package:burumy/design/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

const w = 393.0;

FakeBackend sample(bool ko) => demoSample(ko, File('test/assets/sample_photo.png').readAsBytesSync());

List<String> audit(WidgetTester t, String screen) {
  final bad = <String>[];
  bool near(double a, double b) => (a - b).abs() <= 0.6;

  // 1. Top bar: buttons the same height, on one centre line, and the
  // outer gaps on the left and right the same.
  for (final bar in find.byType(GlassTopBar).evaluate()) {
    final r = t.getRect(find.byElementPredicate((e) => e == bar));
    if (r.width < w - 1 || r.top > 1) continue; // only the page's own bar
    final buttons = find.descendant(
      of: find.byElementPredicate((e) => e == bar),
      matching: find.byWidgetPredicate((x) => x is GlassCircle || x is GlassPill || x is GlassBack || x is GlassDone),
    );
    final rects = [for (final e in buttons.evaluate()) t.getRect(find.byElementPredicate((x) => x == e))]..removeWhere((r) => r.width == 0);
    // GlassBack contains a GlassCircle: keep outermost only.
    final outer = [
      for (final a in rects)
        if (!rects.any(
          (b) => b != a && b.contains(a.topLeft + const Offset(0.1, 0.1)) && b.contains(a.bottomRight - const Offset(0.1, 0.1)) && b.width > a.width,
        ))
          a,
    ];
    if (outer.isEmpty) continue;
    final h = outer.first.height;
    final cy = outer.first.center.dy;
    for (final b in outer) {
      if (!near(b.height, h)) bad.add('$screen: top-bar button heights differ (${b.height} vs $h)');
      if (!near(b.center.dy, cy)) bad.add('$screen: top-bar buttons not on one line (${b.center.dy} vs $cy)');
    }
    final left = outer.where((b) => b.center.dx < w / 2).toList();
    final right = outer.where((b) => b.center.dx > w / 2).toList();
    if (left.isNotEmpty && right.isNotEmpty) {
      final lm = left.map((b) => b.left).reduce((a, b) => a < b ? a : b);
      final rm = w - right.map((b) => b.right).reduce((a, b) => a > b ? a : b);
      if (!near(lm, rm)) bad.add('$screen: top-bar side gaps differ (left $lm, right $rm)');
    }
  }

  // 2. Cards: 16pt from both edges.
  for (final e in find.byType(IosSection).evaluate()) {
    final clip = find.descendant(of: find.byElementPredicate((x) => x == e), matching: find.byType(ClipPath));
    if (clip.evaluate().isEmpty) continue;
    final r = t.getRect(clip.first);
    if (r.width == 0) continue;
    final s = e.widget as IosSection;
    if (s.margin != null) {
      // custom margin must still be symmetric
      if (!near(r.left, w - r.right)) bad.add('$screen: card not centred (${r.left} / ${w - r.right})');
      continue;
    }
    if (!near(r.left, IosSection.sideMargin) || !near(w - r.right, IosSection.sideMargin)) {
      bad.add('$screen: card margins ${r.left} / ${w - r.right} (want ${IosSection.sideMargin})');
    }
  }

  // 3. One-line rows in cards: all 52pt tall.
  for (final e in find.descendant(of: find.byType(IosSection), matching: find.byWidgetPredicate((w) => w is CupertinoListTile)).evaluate()) {
    final tile = e.widget as CupertinoListTile;
    final r = t.getRect(find.byElementPredicate((x) => x == e));
    if (r.height == 0) continue;
    if (tile.subtitle == null && !near(r.height, IosSection.rowHeight)) {
      bad.add('$screen: row "${tile.key ?? (tile.title is Text ? (tile.title as Text).data : '')}" is ${r.height} tall (want ${IosSection.rowHeight})');
    }
  }

  // 4. Tab bar centred.
  for (final e in find.byType(FloatingTabBar).evaluate()) {
    final bar = find.descendant(of: find.byElementPredicate((x) => x == e), matching: find.byType(LiquidGlass)).first;
    final r = t.getRect(bar);
    if (r.width > 0 && !near(r.left, w - r.right)) bad.add('$screen: tab bar not centred (${r.left} / ${w - r.right})');
  }

  // 5. Composer: "+" and send the same size, on one line, same side gaps.
  final plus = find.byKey(const Key('attach'));
  final send = find.byKey(const Key('send')).evaluate().isNotEmpty ? find.byKey(const Key('send')) : find.byKey(const Key('mic'));
  if (plus.evaluate().isNotEmpty && send.evaluate().isNotEmpty) {
    final a = t.getRect(plus.first), b = t.getRect(send.first);
    if (!near(a.height, b.height) || !near(a.width, b.width)) bad.add('$screen: + (${a.size}) and send (${b.size}) differ');
    if (!near(a.center.dy, b.center.dy)) bad.add('$screen: + and send not on one line');
    if (!near(a.left, w - b.right)) bad.add('$screen: composer side gaps differ (${a.left} / ${w - b.right})');
    final field = find.byKey(const Key('composer'));
    if (field.evaluate().isNotEmpty) {
      final c = t.getRect(field.first);
      if (!near(c.center.dy, a.center.dy)) bad.add('$screen: message field not on the buttons\' line (${c.center.dy} vs ${a.center.dy})');
      if (!near(c.height, a.height)) bad.add('$screen: message field ${c.height} tall, buttons ${a.height}');
      if (!near(c.left - a.right, b.left - c.right)) bad.add('$screen: gaps around the field differ (${c.left - a.right} / ${b.left - c.right})');
    }
  }
  // 6. Type: only the eight rulebook sizes, never heavier than 600.
  final sizes = {for (final t in Tokens.all) t.size};
  void walk(RenderObject r) {
    if (r is RenderParagraph && r.attached && r.size.width > 0) {
      final text = r.text.toPlainText().trim();
      if (text.isNotEmpty && !_isArt(r)) {
        void span(InlineSpan sp, TextStyle? parent) {
          final st = parent == null ? sp.style : parent.merge(sp.style);
          if (sp is TextSpan && (sp.text ?? '').trim().isNotEmpty) {
            final fs = st?.fontSize ?? 14;
            final fw = st?.fontWeight ?? FontWeight.w400;
            final emojiOnly = RegExp(r'^[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}\s]+$', unicode: true).hasMatch(sp.text!);
            final iconGlyph = st?.fontFamily == 'CupertinoIcons' || (st?.fontFamily ?? '').contains('cupertino_icons');
            if (!emojiOnly && !iconGlyph) {
              if (!sizes.contains(fs)) bad.add('$screen: text "${_short(sp.text!)}" is ${fs}pt (allowed ${sizes.toList()..sort()})');
              // 700 only for the settings header card title (iOS 27, Eric 2026-11-25).
              final headerTitle = fs == Tokens.headerTitle.size && fw == Tokens.headerTitle.weight;
              if (fw.value > 600 && !headerTitle) bad.add('$screen: text "${_short(sp.text!)}" weight ${fw.value} (max 600)');
            }
          }
          sp.visitDirectChildren((c) {
            span(c, st);
            return true;
          });
        }

        span(r.text, null);
      }
    }
    r.visitChildrenForSemantics(walk);
  }

  walk(t.binding.rootElement!.renderObject!);
  return bad;
}

String _short(String s) => s.length > 14 ? '${s.substring(0, 14)}…' : s;

/// Drawn art (QR, wallpaper, stickers, bubbles) may use any size.
bool _isArt(RenderObject r) {
  final c = r.debugCreator;
  if (c is! DebugCreator) return false;
  var art = false;
  c.element.visitAncestorElements((e) {
    final n = e.widget.runtimeType.toString();
    if (const {'Avatar', 'PhotoAvatar', 'WallpaperArt', 'BurumyMark', 'StickerView', 'MapArt', 'SoapBubble', 'BigEmoji'}.contains(n)) {
      art = true;
      return false;
    }
    return true;
  });
  return art;
}

void main() {
  for (final (dark, family) in [(false, BrandFamily.green), (true, BrandFamily.blue)]) {
    testWidgets('layout is symmetric and even (${dark ? 'dark' : 'light'})', (t) async {
      t.view.physicalSize = const Size(w * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
      final state = AppState(sample(true), family: family, locale: const Locale('ko'));
      await state.backend.login(id: 'me', password: 'x');
      await state.refresh();
      await t.pumpWidget(BurumyApp(state: state));
      await t.pumpAndSettle();
      final bad = <String>[];
      Future<void> look(String name) async {
        await t.pumpAndSettle();
        bad.addAll(audit(t, name));
      }

      Future<void> back() async {
        await t.tap(find.byKey(const Key('back')).last);
        await t.pumpAndSettle();
      }

      await look('chats');
      for (final chat in ['김민지', '디자인 팀', '부루미 소식']) {
        if (find.text(chat).evaluate().isEmpty) {
          final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
          await t.scrollUntilVisible(find.text(chat), 200, scrollable: list);
          await t.pumpAndSettle();
        }
        await t.tap(find.text(chat).last);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await look('chat $chat');
        await t.tap(find.byKey(const Key('chat-title')));
        await look('info $chat');
        await back();
        await back();
      }
      await t.tap(find.text('연락처').last);
      await look('contacts');
      await t.tap(find.text('통화').last);
      await look('calls');
      await t.tap(find.text('설정').last);
      await look('settings');
      for (final row in [
        'my-qr',
        'security-check',
        'backup-row',
        'account-row',
        'look-row',
        'power-row',
        'language-row',
        'notify-row',
        'devices-row',
        'chats-row',
        'data-row',
        'privacy-row',
        'faq-row',
        'tour-row',
        'about-row',
      ]) {
        final f = find.byKey(Key(row));
        if (row != 'my-qr') {
          await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).last);
          unawaited(Scrollable.ensureVisible(t.element(f), alignment: 0.5));
          await t.pumpAndSettle();
        }
        await t.tap(f);
        await t.pumpAndSettle();
        if (row == 'backup-row') {
          // an action sheet, not a page
          await t.tapAt(const Offset(w / 2, 100));
          await t.pumpAndSettle();
          continue;
        }
        await look('settings > $row');
        await back();
      }
      expect(bad.toSet().toList(), isEmpty);
    });
  }
}
