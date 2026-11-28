// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 이모지 찾기·반응 + 스티커 묶음 (tip batches #19 + #20):
// - 김민지 is on holiday (🏖️ for 2 days) and 박서준 at work (💼): their
//   emoji show after their names in the list, the chat title and profile.
// - 김민지 sent her set '민지의 겨울 묶음' in our chat (card with 보기).
// - 디자인 팀 got '회사 짤 묶음' (shows up in 둘러보기 > 대화에서 본 묶음).
// - I already made '내 최애 묶음' (its own section in the sticker panel;
//   type 😂 alone to see it suggested).
import 'dart:convert';

import '../core/backend.dart';
import '../core/sticker_sets.dart';
import 'demo_backend.dart';

Future<void> addEmojiStickerSample(FakeBackend b, bool ko) async {
  final now = DateTime.now();
  b.statuses['@mina:test'] = EmojiStatus('🏖️', now.add(const Duration(days: 2)));
  b.statuses['@leo:test'] = const EmojiStatus('💼');

  Future<String> upload(StickerSet s) => b.uploadEncrypted(utf8.encode(jsonEncode(s.payload())));

  final minas = StickerSet(
    id: 'demo-mina',
    name: ko ? '민지의 겨울 묶음' : "Mina's winter set",
    items: const [
      SetItem(id: 'mongi_07_night', emoji: '🌙'),
      SetItem(id: 'buru_03_love', emoji: '❤️'),
      SetItem(id: 'dugi_05_lol', emoji: '😂'),
      SetItem(id: 'rumi_11_congrats', emoji: '🎉'),
      SetItem(id: 'duru_02_thanks', emoji: '🙏'),
      SetItem(id: 'burumi_09_wow', emoji: '😮'),
      SetItem(id: 'mongi_10_sad', emoji: '😢'),
    ],
  );
  final team = StickerSet(
    id: 'demo-team',
    name: ko ? '회사 짤 묶음' : 'Office set',
    items: const [
      SetItem(id: 'dugi_12_fighting', emoji: '💪'),
      SetItem(id: 'buru_14_ok', emoji: '👌'),
      SetItem(id: 'rumi_13_hmm', emoji: '🤔'),
      SetItem(id: 'duru_16_dizzy', emoji: '😵'),
    ],
  );
  Msg card(String id, String sender, StickerSet s, String file, Duration ago) => Msg(
    id: id,
    sender: sender,
    body: '🎨 ${s.name}',
    time: now.subtract(ago),
    mine: false,
    kind: 'card',
    card: CardInfo(kind: 'stickers', data: {'file': jsonDecode(file), 'name': s.name, 'n': s.items.length, 'kind': 'sticker'}),
  );
  b.rooms['!r0']?.add(card('set-mina', '@mina:test', minas, await upload(minas), const Duration(seconds: 20)));
  b.rooms['!r1']?.add(card('set-team', '@leo:test', team, await upload(team), const Duration(minutes: 3)));

  final mine = StickerSet(
    id: 'demo-mine',
    name: ko ? '내 최애 묶음' : 'My favourites',
    mine: true,
    items: const [
      SetItem(id: 'buru_05_lol', emoji: '😂'),
      SetItem(id: 'remy_s03_lol', emoji: '😂'),
      SetItem(id: 'kai_s01_hello', emoji: '👋'),
      SetItem(id: 'burumi_03_love', emoji: '❤️'),
      SetItem(id: 'mongi_12_fighting', emoji: '💪'),
    ],
  );
  b.prefs[StickerSets.key] = jsonEncode([mine.toJson()]);
}
