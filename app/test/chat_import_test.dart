// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 대화 가져오기: reading KakaoTalk, WhatsApp and Telegram exports (samples
// written by us in each app's export shape).
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:burumy/core/chat_import.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List u(String s) => Uint8List.fromList(utf8.encode(s));

Uint8List zip(Map<String, List<int>> files) {
  final a = Archive();
  for (final e in files.entries) {
    a.addFile(ArchiveFile(e.key, e.value.length, e.value));
  }
  return Uint8List.fromList(ZipEncoder().encode(a));
}

void main() {
  group('KakaoTalk', () {
    test('phone export (Korean): names, 12-hour times, long messages, notices, photo lines', () {
      const text = '''김민지 님과 카카오톡 대화
저장한 날짜 : 2024. 5. 3. 오후 4:12

2024년 5월 1일 수요일
2024. 5. 1. 오전 9:05, 김민지 : 좋은 아침!
2024. 5. 1. 오후 12:30, 나 : 점심 뭐 먹을래?
두 줄째예요
2024. 5. 1. 오후 12:31, 김민지 : 사진
2024. 5. 1. 오후 1:00, 김민지 : 삭제된 메시지입니다.
2024. 5. 1. 오후 1:01, 김민지 : 파일: 계획서.pdf
2024. 5. 2. 오전 12:10: 박지수님이 들어왔습니다.
''';
      final c = ChatImport.read('KakaoTalkChats.txt', u(text)).chats.single;
      expect(c.app, ImportApp.kakao);
      expect(c.title, '김민지');
      expect(c.items.length, 6);
      expect(c.items[0].time, DateTime(2024, 5, 1, 9, 5));
      expect(c.items[0].from, '김민지');
      expect(c.items[1].time, DateTime(2024, 5, 1, 12, 30));
      expect(c.items[1].body, '점심 뭐 먹을래?\n두 줄째예요');
      expect(c.items[2].kind, 'missing');
      expect(c.items[2].missingKind, 'image');
      expect(c.items[3].kind, 'deleted');
      expect(c.items[4].missingKind, 'file');
      expect(c.items[4].body, '계획서.pdf');
      expect(c.items[5].kind, 'system');
      expect(c.items[5].time, DateTime(2024, 5, 2, 0, 10));
      expect(c.people, ['김민지', '나']);
    });

    test('older phone export (년 월 일) and 24-hour times', () {
      const text = '''친구들 4 카카오톡 대화
저장한 날짜 : 2023년 3월 2일 오후 3:00

2023년 3월 1일 오후 11:59, 철수 : 자정 전
2023년 3월 2일 00:01, 영희 : 자정 후
''';
      final c = ChatImport.read('chat.txt', u(text)).chats.single;
      expect(c.title, '친구들');
      expect(c.items[0].time, DateTime(2023, 3, 1, 23, 59));
      expect(c.items[1].time, DateTime(2023, 3, 2, 0, 1));
    });

    test('PC export: day lines and [name] [time]', () {
      const text = '''회사 동기 님과 카카오톡 대화
저장한 날짜 : 2024-01-03 10:00:00

--------------- 2024년 1월 2일 화요일 ---------------
[이수진] [오후 3:04] 안녕하세요
[나] [오후 3:05] 네 안녕하세요
줄바꿈
--------------- 2024년 1월 3일 수요일 ---------------
[이수진] [오전 12:00] 새해 복
''';
      final c = ChatImport.read('KakaoTalk_20240103.txt', u(text)).chats.single;
      expect(c.app, ImportApp.kakao);
      expect(c.items.length, 3);
      expect(c.items[0].time, DateTime(2024, 1, 2, 15, 4));
      expect(c.items[1].body, '네 안녕하세요\n줄바꿈');
      expect(c.items[2].time, DateTime(2024, 1, 3, 0, 0));
    });

    test('csv export with a message over two lines', () {
      const text = 'Date,User,Message\n2024-02-01 08:00:00,"민수","아침"\n2024-02-01 08:01:00,"지은","첫 줄\n둘째 줄, 쉼표"\n';
      final c = ChatImport.read('Talk.csv', u(text)).chats.single;
      expect(c.app, ImportApp.kakao);
      expect(c.items.length, 2);
      expect(c.items[1].body, '첫 줄\n둘째 줄, 쉼표');
      expect(c.items[1].time, DateTime(2024, 2, 1, 8, 1));
    });

    test('English phone export', () {
      const text = 'KakaoTalk Chats with Sam\nDate Saved : May 3, 2024 at 4:12 PM\n\nMay 1, 2024 at 9:05 PM, Sam : hello\nMay 1, 2024 at 9:06 PM, Me : Photo\n';
      final c = ChatImport.read('chat.txt', u(text)).chats.single;
      expect(c.app, ImportApp.kakao);
      expect(c.title, 'Sam');
      expect(c.items[0].time, DateTime(2024, 5, 1, 21, 5));
      expect(c.items[1].missingKind, 'image');
    });

    test('"save everything" zip: a photo line takes the photo sent in that minute', () {
      const text = '김민지 님과 카카오톡 대화\n\n2024. 5. 1. 오후 12:31, 김민지 : 사진\n2024. 5. 1. 오후 12:40, 김민지 : 사진\n';
      final b = ChatImport.read(
        'KakaoTalk_Chats.zip',
        zip({
          'Talk_2024.5.3 16:12-1.txt': utf8.encode(text),
          'KakaoTalk_20240501_123112345.jpg': [1, 2, 3],
        }),
      );
      final c = b.chats.single;
      expect(c.items[0].kind, 'image');
      expect(c.items[0].media, 'KakaoTalk_20240501_123112345.jpg');
      expect(c.items[1].kind, 'missing', reason: 'no photo from 12:40 in the zip');
      expect(b.files.read(c.items[0].media!), [1, 2, 3]);
    });
  });

  group('WhatsApp', () {
    test('iPhone export (English, month first) with attachment in the zip', () {
      const text =
          '[1/2/24, 2:30:15 PM] Sam: Messages and calls are end-to-end encrypted.\n'
          '[1/2/24, 2:30:15 PM] Sam: hi\n'
          '[1/2/24, 2:31:00 PM] Alex: \u200e<attached: 00000012-PHOTO-2024-01-02-14-31-00.jpg>\n'
          '[1/13/24, 9:00:00 AM] Alex: two\nlines\n'
          '[1/13/24, 9:01:00 AM] Sam: \u200eimage omitted\n';
      final b = ChatImport.read(
        'WhatsApp Chat - Sam.zip',
        zip({
          '_chat.txt': utf8.encode(text),
          '00000012-PHOTO-2024-01-02-14-31-00.jpg': [9, 9],
        }),
      );
      final c = b.chats.single;
      expect(c.app, ImportApp.whatsapp);
      expect(c.items.length, 5);
      expect(c.items[1].body, 'hi');
      expect(c.items[1].time, DateTime(2024, 1, 2, 14, 30, 15));
      expect(c.items[2].kind, 'image');
      expect(c.items[2].media, '00000012-PHOTO-2024-01-02-14-31-00.jpg');
      expect(c.items[3].time, DateTime(2024, 1, 13, 9, 0));
      expect(c.items[3].body, 'two\nlines');
      expect(c.items[4].kind, 'missing');
    });

    test('Android export (day first, 24 h) and notices without a writer', () {
      const text =
          '02/01/2024, 14:30 - Messages and calls are end-to-end encrypted. Tap to learn more.\n'
          '13/01/2024, 09:00 - Ana: olá\n'
          '13/01/2024, 09:01 - Ana created group "Trip"\n'
          '13/01/2024, 09:02 - Ben: IMG-20240113-WA0001.jpg (file attached)\nnice\n';
      final b = ChatImport.read(
        'WhatsApp Chat with Trip.zip',
        zip({
          'WhatsApp Chat with Trip.txt': utf8.encode(text),
          'IMG-20240113-WA0001.jpg': [1],
        }),
      );
      final c = b.chats.single;
      expect(c.app, ImportApp.whatsapp);
      expect(c.title, 'Trip');
      expect(c.items[0].time, DateTime(2024, 1, 13, 9, 0));
      expect(c.items[1].kind, 'system');
      expect(c.items[2].kind, 'image');
      expect(c.items[2].body, 'nice');
    });

    test('Korean Android export', () {
      const text = '2024. 1. 2. 오후 2:30 - 홍길동: 안녕\n2024. 1. 2. 오후 2:31 - 김영희: <미디어 파일 생략됨>\n';
      final c = ChatImport.read('WhatsApp 채팅 - 홍길동.txt', u(text)).chats.single;
      expect(c.app, ImportApp.whatsapp);
      expect(c.title, '홍길동');
      expect(c.items[0].time, DateTime(2024, 1, 2, 14, 30));
      expect(c.items[1].kind, 'missing');
    });
  });

  group('Telegram', () {
    final json = jsonEncode({
      'name': 'Sam',
      'type': 'personal_chat',
      'messages': [
        {'id': 1, 'type': 'message', 'date': '2024-01-02T14:30:15', 'date_unixtime': '1704173415', 'from': 'Sam', 'text': 'hi'},
        {
          'id': 2,
          'type': 'message',
          'date': '2024-01-02T14:31:00',
          'date_unixtime': '1704173460',
          'from': 'Me',
          'text': [
            'see ',
            {'type': 'bold', 'text': 'this'},
          ],
          'reply_to_message_id': 1,
          'photo': 'photos/photo_1@02-01-2024_14-31-00.jpg',
        },
        {
          'id': 3,
          'type': 'message',
          'date_unixtime': '1704173500',
          'from': 'Sam',
          'file': '(File not included. Change data exporting settings to download.)',
          'media_type': 'video_file',
          'text': '',
        },
        {'id': 4, 'type': 'service', 'date_unixtime': '1704173600', 'actor': 'Sam', 'action': 'pin_message', 'text': ''},
        {
          'id': 5,
          'type': 'message',
          'date_unixtime': '1704173700',
          'from': 'Sam',
          'file': 'voice_messages/audio_1.ogg',
          'media_type': 'voice_message',
          'text': '',
        },
      ],
    });

    test('result.json: rich text, replies, photos, missing files, notices', () {
      final c = ChatImport.read('result.json', u(json)).chats.single;
      expect(c.app, ImportApp.telegram);
      expect(c.title, 'Sam');
      expect(c.items[0].time, DateTime.fromMillisecondsSinceEpoch(1704173415000));
      expect(c.items[1].body, 'see this');
      expect(c.items[1].replyTo, 0);
      expect(c.items[2].kind, 'missing');
      expect(c.items[2].missingKind, 'video');
      expect(c.items[3].body, 'sys:pin|Sam');
      // Without the folder the photo and voice can't come along.
      final b = ChatImport.read('result.json', u(json));
      expect(b.files.has('photos/photo_1@02-01-2024_14-31-00.jpg'), isFalse);
    });

    test('zipped export folder brings the photos along', () {
      final b = ChatImport.read(
        'Telegram.zip',
        zip({
          'ChatExport_2024-01-03/result.json': utf8.encode(json),
          'ChatExport_2024-01-03/photos/photo_1@02-01-2024_14-31-00.jpg': [7],
        }),
      );
      final c = b.chats.single;
      expect(c.items[1].kind, 'image');
      expect(b.files.read(c.items[1].media!), [7]);
      expect(c.items[4].kind, 'missing', reason: 'voice file not in the zip');
    });

    test('whole-account export lists each chat', () {
      final all = jsonEncode({
        'chats': {
          'list': [
            {
              'name': 'A',
              'messages': [
                {'id': 1, 'type': 'message', 'date_unixtime': '1704173415', 'from': 'A', 'text': 'x'},
              ],
            },
            {
              'name': 'B',
              'messages': [
                {'id': 1, 'type': 'message', 'date_unixtime': '1704173415', 'from': 'B', 'text': 'y'},
              ],
            },
          ],
        },
      });
      expect(ChatImport.read('result.json', u(all)).chats.map((c) => c.title), ['A', 'B']);
    });

    test('messages.html', () {
      const html = '''<div class="page_header"><div class="text bold">Sam</div></div>
<div class="message service" id="message-1"><div class="body details">2 January 2024</div></div>
<div class="message default clearfix" id="message10"><div class="body">
<div class="pull_right date details" title="02.01.2024 14:30:15 UTC+09:00">14:30</div>
<div class="from_name">Sam </div>
<div class="text">hi &amp; <strong>bye</strong><br>line</div></div></div>
<div class="message default clearfix joined" id="message11"><div class="body">
<div class="pull_right date details" title="02.01.2024 14:31:00 UTC+09:00">14:31</div>
<div class="reply_to details">In reply to <a href="#go_to_message10">this message</a></div>
<div class="media_wrap clearfix"><a class="photo_wrap clearfix pull_left" href="photos/photo_2.jpg"></a></div>
</div></div>''';
      final c = ChatImport.read('messages.html', u(html)).chats.single;
      expect(c.title, 'Sam');
      expect(c.items.length, 2);
      expect(c.items[0].body, 'hi & bye\nline');
      expect(c.items[0].time, DateTime.utc(2024, 1, 2, 5, 30, 15).toLocal());
      expect(c.items[1].from, 'Sam');
      expect(c.items[1].kind, 'missing', reason: 'photo file not picked along');
      expect(c.items[1].replyTo, 0);
    });
  });

  test('things that are not chats say so', () {
    expect(() => ChatImport.read('x.txt', u('just some words\nno times')), throwsA(isA<ImportError>()));
    expect(() => ChatImport.read('x.zip', Uint8List.fromList([0x50, 0x4b, 3, 4, 0, 0])), throwsA(isA<ImportError>()));
    expect(() => ChatImport.read('x.json', u('{"a":1}')), throwsA(isA<ImportError>()));
  });
}
