// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tip batches #25 + #26: 긴 글 AI 요약 (554), 읽기 모드 (475),
// 동그란 영상 글로 보기 (361), 음악 재생 목록 + 미니 플레이어 (108) and
// 속도 · 이어 듣기 (199).
import 'dart:async';
import 'dart:typed_data';

import 'package:burumy/core/ai_local.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/audio_dock.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/reader.dart';
import 'package:burumy/demo/audio_reader_sample.dart';
import 'package:burumy/demo/demo_ai.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/post_summary.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

class _NoAi implements AiEngine {
  @override
  Future<AiStatus> status() async => AiStatus.unsupported;
  @override
  Future<String> run({required String rules, required String text}) async => throw const AiError('unsupported');
}

/// Plays nothing; reports a fixed length and moves when told.
class FakeEngine implements AudioEngine {
  static final loaded = <String>[];
  static Duration length = const Duration(minutes: 3);
  final pos = StreamController<Duration>.broadcast();
  final on = StreamController<bool>.broadcast();
  final end = StreamController<void>.broadcast();
  double speed = 1;
  Duration? seeked;

  @override
  Future<Duration?> load(Uint8List bytes, String name) async {
    loaded.add(name);
    return length;
  }

  @override
  Future<void> play() async => on.add(true);
  @override
  Future<void> pause() async => on.add(false);
  @override
  Future<void> seek(Duration at) async {
    seeked = at;
    pos.add(at);
  }

  @override
  Future<void> setSpeed(double v) async => speed = v;
  @override
  Stream<Duration> get position => pos.stream;
  @override
  Stream<bool> get playing => on.stream;
  @override
  Stream<void> get ended => end.stream;
  @override
  Future<void> dispose() async {}
}

const _page = '''
<html><head>
<title>골목길 서점 - 도시 산책</title>
<meta property="og:site_name" content="도시 산책">
<meta property="og:title" content="골목길 서점이 다시 늘어나는 이유">
<meta property="og:image" content="/img/cover.jpg">
<meta name="author" content="한소리 기자">
<script>var ads = 1;</script>
</head><body>
<header><nav><a href="/">홈</a><a href="/news">뉴스</a></nav></header>
<aside class="sidebar"><p>많이 본 기사 목록이 여기 있어요. 이건 본문이 아니에요. 광고 광고 광고 광고 광고.</p></aside>
<div class="content">
 <h1>골목길 서점이 다시 늘어나는 이유</h1>
 <p>성수동 골목에 작은 독립 서점 다섯 곳이 지난 1년 사이 새로 문을 열었어요. 큰 서점이 문을 닫는 동안 작은 서점은 늘고 있어요.</p>
 <figure><img src="/img/shop.jpg" width="800"><figcaption>골목의 한 서점</figcaption></figure>
 <h2>서점마다 다른 색</h2>
 <p>어떤 곳은 동네 작가의 책만 모아 두고, 어떤 곳은 밤 9시부터 자정까지 조용히 책만 읽는 모임을 열어요.</p>
 <blockquote>책 옆에 앉아 있으려고 오는 분이 많아요.</blockquote>
 <ul><li>주말 오후 2시~5시: 가장 붐벼요</li><li>평일 저녁: 한가해요</li></ul>
 <p>서점 주인들은 동네 사람들이 서로 얼굴을 아는 곳으로 남고 싶다고 말해요. 다음 달에는 산책 지도도 나와요.</p>
 <img src="/pixel.gif" width="1">
</div>
<footer><p>저작권 안내 문구가 여기 있어요. 무단 전재 금지. 모든 권리 보유.</p></footer>
</body></html>
''';

void main() {
  setUp(() {
    Features.tipsAiRead = true;
    Features.tipsAudio = true;
  });
  tearDown(() async {
    Features.tipsAiRead = false;
    Features.tipsAudio = false;
    LocalAi.engine = PhoneAi();
    LocalAi.reset();
    Reader.debug = null;
    await AudioDock.instance.reset();
    AudioDock.makeEngine = JustAudioEngine.new;
  });

  group('읽기 모드 (475)', () {
    test('picks the article out of a page, drops menus and ads', () {
      final a = Reader.parse(_page, Uri.parse('https://news.example/a/1'))!;
      expect(a.title, '골목길 서점이 다시 늘어나는 이유');
      expect(a.site, '도시 산책');
      expect(a.byline, '한소리 기자');
      expect(a.image, 'https://news.example/img/cover.jpg');
      final kinds = a.blocks.map((b) => b.kind).toList();
      expect(kinds, ['p', 'img', 'h', 'p', 'quote', 'li', 'li', 'p']);
      expect(a.blocks[1].src, 'https://news.example/img/shop.jpg');
      expect(a.blocks[1].text, '골목의 한 서점');
      expect(a.text, isNot(contains('광고')));
      expect(a.text, isNot(contains('저작권')));
      expect(a.text, isNot(contains('홈')));
      expect(a.minutes, 1);
    });

    test('a page without an article: null', () {
      expect(Reader.parse('<html><body><nav>메뉴</nav><p>짧아요</p></body></html>', Uri.parse('https://x.example')), isNull);
    });

    test('offered for article pages, not videos, apps or files', () {
      expect(Reader.offered('https://news.example/a/1'), isTrue);
      expect(Reader.offered('https://www.youtube.com/watch?v=1'), isFalse);
      expect(Reader.offered('https://youtu.be/1'), isFalse);
      expect(Reader.offered('https://apps.apple.com/app/1'), isFalse);
      expect(Reader.offered('https://x.example/file.pdf'), isFalse);
      expect(Reader.offered('ftp://x.example/a'), isFalse);
      expect(Reader.offered('nonsense'), isFalse);
    });
  });

  group('음악 (108, 199)', () {
    test('sound type from the first bytes', () {
      expect(audioMime(demoTune([0], seconds: 0.1), 'x'), 'audio/wav');
      expect(audioMime(Uint8List.fromList([0x49, 0x44, 0x33, 0, 0, 0]), 'x.bin'), 'audio/mpeg');
      expect(audioMime(Uint8List.fromList([0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70, 0, 0]), 'x'), 'audio/mp4');
      expect(audioMime(Uint8List.fromList([1, 2, 3]), 'song.flac'), 'audio/flac');
    });

    test('"Artist - Title" names', () {
      const t = Track(roomId: 'r', msgId: 'm', name: 'Lumen - Morning_Walk.mp3');
      expect(t.artist, 'Lumen');
      expect(t.title, 'Morning Walk');
      const u = Track(roomId: 'r', msgId: 'm', name: 'voice memo.m4a');
      expect(u.artist, isNull);
      expect(u.title, 'voice memo');
    });

    test('play list: next, repeat, speed and carrying on where I stopped', () async {
      final engines = <FakeEngine>[];
      AudioDock.makeEngine = () => (engines..add(FakeEngine())).last;
      FakeEngine.loaded.clear();
      final prefs = <String, String>{AudioDock.posKey('b'): '42000'};
      final dock = AudioDock.instance;
      await dock.start(
        list: const [
          Track(roomId: 'r', msgId: 'a', name: 'A - One.mp3'),
          Track(roomId: 'r', msgId: 'b', name: 'A - Two.mp3'),
          Track(roomId: 'r', msgId: 'c', name: 'A - Three.mp3'),
        ],
        at: 0,
        chatName: '채원',
        download: (_, _) async => [1, 2, 3],
        read: (k) => prefs[k] ?? '',
        write: (k, v) async => v.isEmpty ? prefs.remove(k) : prefs[k] = v,
        speed: 1.5,
      );
      final e = engines.single;
      expect(FakeEngine.loaded, ['A - One.mp3']);
      expect(e.speed, 1.5);
      expect(dock.current!.title, 'One');

      // Next track remembers 42 s and starts there.
      await dock.next();
      expect(dock.index, 1);
      expect(e.seeked, const Duration(seconds: 42));

      // Pausing a long track keeps the place.
      e.pos.add(const Duration(seconds: 70));
      e.on.add(true);
      await Future<void>.delayed(Duration.zero);
      e.on.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(prefs[AudioDock.posKey('b')], '70000');

      // The end of the list stops, unless it repeats.
      await dock.jump(2);
      e.end.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(dock.index, 2);
      dock.cycleRepeat(); // all
      expect(dock.repeat, Repeat.all);
      await dock.next();
      expect(dock.index, 0);

      // Previous near the start goes back a track; later it restarts.
      dock.position = const Duration(seconds: 1);
      await dock.previous();
      expect(dock.index, 0);
      await dock.jump(1);
      dock.position = const Duration(seconds: 10);
      await dock.previous();
      expect(dock.index, 1);
      expect(e.seeked, Duration.zero);

      expect(dock.nextSpeed, 2);
      await dock.setSpeed(2);
      expect(dock.nextSpeed, 1);
      expect(e.speed, 2);

      await dock.close();
      expect(dock.active, isFalse);
    });
  });

  group('screens', () {
    Future<(FakeBackend, AppState)> app(WidgetTester t, {AiEngine? ai}) async {
      t.view.physicalSize = const Size(1179, 2556);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      LocalAi.engine = ai ?? DemoAi(delay: Duration.zero);
      LocalAi.reset();
      await LocalAi.status();
      AudioDock.makeEngine = FakeEngine.new;
      final fake = FakeBackend();
      final state = AppState(fake, locale: const Locale('ko'));
      await fake.login(id: 'me', password: 'x');
      addAudioReaderSample(fake, true);
      Reader.debug = (u) async => demoArticle(u, true);
      await state.refresh();
      await t.pumpWidget(BurumyApp(state: state));
      await t.pumpAndSettle();
      return (fake, state);
    }

    testWidgets('긴 글 요약: button, summary in place, back to the post (ko)', (t) async {
      await app(t);
      await t.tap(find.text('도시 산책 매거진'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('post-summary-cw1')), findsOneWidget);
      // The short link post gets no button.
      expect(find.byKey(const Key('post-summary-cw2')), findsNothing);
      await t.ensureVisible(find.byKey(const Key('post-summary-cw1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('post-summary-cw1')));
      await t.pumpAndSettle();
      expect(find.textContaining('• 12월 14일(토) 오전 10시'), findsOneWidget);
      expect(find.text('원문 보기'), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('post-summary-cw1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('post-summary-cw1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('post-summary-box')), findsNothing);
      expect(find.textContaining('올해 마지막 도시 산책은'), findsOneWidget);
    });

    testWidgets('긴 글 요약: none without phone AI (ko)', (t) async {
      await app(t, ai: _NoAi());
      await t.tap(find.text('도시 산책 매거진'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('post-summary-cw1')), findsNothing);
    });

    test('summary only for long text posts in rooms', () {
      final long = Msg(id: 'x', sender: 's', body: '가' * 600, time: DateTime(2026), mine: false, kind: 'text');
      expect(PostSummary.fits(long, room: true), isTrue);
      expect(PostSummary.fits(long, room: false), isFalse);
      expect(PostSummary.fits(Msg(id: 'y', sender: 's', body: '짧아요', time: DateTime(2026), mine: false, kind: 'text'), room: true), isFalse);
    });

    testWidgets('읽기 모드: link card button opens the clean article (ko)', (t) async {
      await app(t);
      await t.tap(find.text('도시 산책 매거진'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('reader-open-cw2')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('reader-page')), findsOneWidget);
      expect(find.byKey(const Key('reader-title')), findsOneWidget);
      expect(find.text('도시 산책 매거진 · 1분 읽기'), findsOneWidget);
      expect(find.text('서점마다 다른 색'), findsOneWidget);
      await t.tap(find.byKey(const Key('reader-summary-open')));
      await t.pumpAndSettle();
      expect(find.textContaining('독립 서점 5곳'), findsWidgets);
      // Aa: bigger text, kept for next time.
      await t.tap(find.byKey(const Key('reader-aa')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('reader-size-sheet')), findsOneWidget);
    });

    testWidgets('음악: tap a song → mini bar + player with the play list (ko)', (t) async {
      await app(t);
      await t.tap(find.text('채원'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('music-mu1')), findsOneWidget);
      expect(find.text('Morning Walk'), findsOneWidget);
      await t.tap(find.byKey(const Key('music-play-mu1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('audio-mini')), findsOneWidget);
      expect(AudioDock.instance.queue.length, 4);
      await t.tap(find.byKey(const Key('audio-speed')));
      await t.pumpAndSettle();
      expect(AudioDock.instance.speed, 1.5);
      await t.pump(const Duration(seconds: 3));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('audio-mini')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('music-player')), findsOneWidget);
      expect(find.text('재생 목록 4곡'), findsOneWidget);
      await t.tap(find.byKey(const Key('music-next')));
      await t.pumpAndSettle();
      expect(AudioDock.instance.current!.title, 'City Lights');
      // Let the toast timers finish.
      await t.pump(const Duration(seconds: 3));
    });
  });
}
