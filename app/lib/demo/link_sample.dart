// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only web demo for batch #4 (링크·서식·보내기): a code block, a date
// mark, a link card set above with a small photo, a waiting scheduled
// message, and a page the composer can preview (try pasting the link).
import 'dart:convert';
import 'dart:typed_data';

import '../core/backend.dart';
import '../core/date_mark.dart';
import 'demo_backend.dart';

void addLinkSample(FakeBackend b, bool ko, Uint8List photo) {
  const room = '!r2';
  final list = b.rooms[room];
  if (list == null) return;
  final now = DateTime.now();
  final sat = DateTime(now.year, now.month, now.day + (DateTime.saturday - now.weekday + 7) % 7 + 1, 10);
  b.storyLinks['https://burumy.app/guide'] = StoryLinkInfo(
    title: ko ? '부루미 처음 쓰는 법' : 'Getting started with Burumy',
    site: 'Burumy',
    description: ko ? '대화, 사진, 통화를 안전하게 쓰는 방법을 모았어요.' : 'Chats, photos and calls, kept safe.',
    image: photo,
  );
  b.storyLinks['https://burumy.app/notes/2'] = StoryLinkInfo(title: ko ? '이번 주 회의 메모' : 'This week\'s notes', site: 'burumy.app', image: photo);
  list.addAll([
    Msg(
      id: 'tl-code',
      sender: '@leo:test',
      body: ko ? '이거 한번 봐 줄래요?\n```python\ndef 두배(숫자들):\n    """받은 숫자를 두 배로"""\n    return [n * 2 for n in 숫자들]  # 리스트로\n\nprint(두배([1, 2, 3]))\n```' : 'Can you check this?\n```python\ndef double(nums):\n    """Twice every number"""\n    return [n * 2 for n in nums]  # as a list\n\nprint(double([1, 2, 3]))\n```',
      time: now.subtract(const Duration(minutes: 40)),
      mine: false,
      kind: 'text',
    ),
    Msg(
      id: 'tl-date',
      sender: '@me:test',
      body: ko ? '좋아요! 스쿼시는 ${dateMarkText('토요일 오전 10시', sat)} 어때요?' : 'Great! Squash ${dateMarkText('Saturday at 10', sat)}?',
      time: now.subtract(const Duration(minutes: 30)),
      mine: true,
      kind: 'text',
    ),
    Msg(
      id: 'tl-link',
      sender: '@me:test',
      body: ko ? '처음 쓰면 이거 보면 돼요 https://burumy.app/guide' : 'New here? Read this https://burumy.app/guide',
      time: now.subtract(const Duration(minutes: 20)),
      mine: true,
      kind: 'text',
      preview: LinkCard(
        url: 'https://burumy.app/guide',
        title: ko ? '부루미 처음 쓰는 법' : 'Getting started with Burumy',
        description: ko ? '대화, 사진, 통화를 안전하게 쓰는 방법을 모았어요.' : 'Chats, photos and calls, kept safe.',
        site: 'Burumy',
        hasImage: true,
        above: true,
        small: true,
      ),
    ),
  ]);
  b.previewImages['tl-link'] = photo;
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
  b.prefs['scheduled'] = jsonEncode([
    {'id': 'tl-s1', 'room': room, 'text': ko ? '생일 축하해요 🎂' : 'Happy birthday 🎂', 'at': tomorrow.millisecondsSinceEpoch, 'quiet': false},
  ]);
}
