// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 테마·배경·꾸미기 (2026-11-27, tip batches #21 + #24):
// - 지수 (1:1): sent me a theme link (card + 테마 보기), set a swirling
//   background for both of us (card at the top: 그대로 두기 / 되돌리기),
//   and her profile has a purple-pink cover with hearts.
// - 독서 모임 (group, I'm the owner): green-teal cover with leaves, 📚
//   status, mint background for everyone; 민호's name runs orange → yellow
//   and a reply to him shows his star icons in the quote.
// - 내 테마: one made theme ready to try (봄 소풍).
import 'dart:convert';
import 'dart:ui' show Color;

import '../core/backend.dart';
import '../core/looks.dart';
import 'demo_backend.dart';

void addLookSample(FakeBackend b, bool ko) {
  final now = DateTime.now();
  DateTime ago(int min) => now.subtract(Duration(minutes: min));
  const jisu = '@jisoo:test', minho = '@minho.k:test';

  // ---- 1:1 with 지수 ----
  const d = '!look_jisu';
  b.names[d] = ko ? '지수' : 'Jisoo';
  b.peers[d] = jisu;
  b.roomMembers[d] = [
    Member(userId: '@me:test', name: 'me', role: 'member', since: ago(60 * 24 * 90)),
    Member(userId: jisu, name: ko ? '지수' : 'Jisoo', role: 'member', since: ago(60 * 24 * 90)),
  ];
  final theme = MyTheme(
    id: 'demo-lavender',
    name: ko ? '라벤더 밤' : 'Lavender night',
    accent: const Color(0xFFB14BE0),
    wall: Wall.gradSpec('lilac', pattern: 'stars'),
  );
  b.rooms[d] = [
    Msg(id: 'lk1', sender: jisu, body: ko ? '내가 만든 테마야, 한번 써 봐 💜' : 'I made this theme, try it 💜', time: ago(30), mine: false, kind: 'text'),
    Msg(id: 'lk2', sender: jisu, body: theme.link(), time: ago(29), mine: false, kind: 'text'),
    Msg(id: 'lk3', sender: '@me:test', body: ko ? '오 예쁘다! 배경도 바꿨네?' : 'Pretty! You changed our background too?', time: ago(20), mine: true, kind: 'text'),
    Msg(
      id: 'lk4',
      sender: jisu,
      body: ko ? '응 우리 둘 다 보이게 했어. 보낼 때마다 색이 살짝 돌아 🌀' : 'Yes, for both of us. The colours turn a little each time you send 🌀',
      time: ago(19),
      mine: false,
      kind: 'text',
    ),
  ];
  final spin = Wall.gradSpec('lilac');
  final at = ago(19).millisecondsSinceEpoch;
  b.prefs['chat_theme:$d'] = spin;
  b.prefs['chat_theme_at:$d'] = '$at';
  b.prefs['chat_theme_by:$d'] = jisu;
  b.prefs['chat_theme_note:$d'] = jsonEncode({'by': jisu, 't': spin, 'at': at, 'prev': ''});
  // Her look, as her encrypted 1:1 note left it on this phone.
  b.prefs[PersonLook.prefOf(jisu)] = 'purple+pink|hearts|purple+pink|hearts';

  // ---- 독서 모임 ----
  const g = '!look_book';
  b.names[g] = ko ? '독서 모임' : 'Book Club';
  b.groups.add(g);
  b.roomMembers[g] = [
    Member(userId: '@me:test', name: 'me', role: 'owner', since: ago(60 * 24 * 60)),
    Member(userId: jisu, name: ko ? '지수' : 'Jisoo', role: 'member', since: ago(60 * 24 * 40)),
    Member(userId: minho, name: ko ? '민호' : 'Minho', role: 'member', since: ago(60 * 24 * 30)),
  ];
  b.demoColors[g] = {jisu: 'purple+pink|hearts|purple+pink|hearts', minho: 'orange+yellow|stars|orange+yellow|stars'};
  b.roomConfigs[g] = {
    ...?b.roomConfigs[g],
    RoomLook.cfgKey: {'c': 'green+teal', 'l': 'nature', 'e': '📚', 'w': Wall.gradSpec('mint', pattern: 'nature')},
  };
  b.rooms[g] = [
    Msg(
      id: 'bk1',
      sender: minho,
      body: ko ? '이번 달 책은 「어린 왕자」 어때요? 짧아서 다 같이 읽기 좋아요 ⭐️' : 'How about The Little Prince this month? Short and easy to read together ⭐️',
      time: ago(90),
      mine: false,
      kind: 'text',
    ),
    Msg(id: 'bk2', sender: jisu, body: ko ? '좋아요! 저는 벌써 반 읽었어요 📖' : 'Yes! I\'m already half way 📖', time: ago(80), mine: false, kind: 'text', replyTo: 'bk1'),
    Msg(
      id: 'bk3',
      sender: '@me:test',
      body: ko ? '그럼 다음 주 토요일 3시에 만나요 ☕️' : 'Then Saturday 3 PM next week ☕️',
      time: ago(60),
      mine: true,
      kind: 'text',
      replyTo: 'bk1',
    ),
  ];

  // ---- 내 테마: one ready to try ----
  b.prefs[MyTheme.pref] = MyTheme.listTo([
    MyTheme(
      id: 'demo-spring',
      name: ko ? '봄 소풍' : 'Spring picnic',
      accent: const Color(0xFFFF2D55),
      wall: Wall.gradSpec('peach', pattern: 'hearts'),
    ),
  ]);
}
