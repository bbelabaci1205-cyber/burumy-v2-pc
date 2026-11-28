// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다른 앱 대화 가져오기 in the look-only demo: a KakaoTalk export (zip with
// one photo) written by us in KakaoTalk's export shape, already brought
// into 김민지's chat, and offered as "예시 파일로 해 보기" on the guide.
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../core/chat_import.dart';
import '../core/chat_import_send.dart';
import '../ui/chat_import_ui.dart' show ImportDemo;
import 'demo_backend.dart';

String _kakaoText(bool ko) => ko
    ? '''김민지 님과 카카오톡 대화
저장한 날짜 : 2025. 3. 2. 오후 9:40

2024년 12월 24일 화요일
2024. 12. 24. 오후 7:02, 김민지 : 메리 크리스마스! 🎄
2024. 12. 24. 오후 7:03, 나 : 메리 크리스마스~ 오늘 뭐 해?
2024. 12. 24. 오후 7:05, 김민지 : 가족이랑 케이크 먹으려고
사진 보내 줄게
2024. 12. 24. 오후 7:06, 김민지 : 사진
2024. 12. 24. 오후 7:08, 나 : 와 맛있겠다 😋
2025년 1월 1일 수요일
2025. 1. 1. 오전 12:00, 나 : 새해 복 많이 받아!
2025. 1. 1. 오전 12:01, 김민지 : 너도 새해 복 많이 받아 🙏
2025. 1. 1. 오전 12:02, 김민지 : 동영상
2025년 3월 2일 일요일
2025. 3. 2. 오후 9:30, 김민지 : 이제 부루미로 옮기자! 대화도 다 가져갈 수 있대
2025. 3. 2. 오후 9:31, 나 : 좋아, 카톡 대화 내보내서 가져올게
'''
    : '''KakaoTalk Chats with Mina Kim
Date Saved : Mar 2, 2025 at 9:40 PM

Dec 24, 2024 at 7:02 PM, Mina Kim : Merry Christmas! 🎄
Dec 24, 2024 at 7:03 PM, Me : Merry Christmas~ What are you up to?
Dec 24, 2024 at 7:05 PM, Mina Kim : Cake with my family
I'll send a photo
Dec 24, 2024 at 7:06 PM, Mina Kim : Photo
Dec 24, 2024 at 7:08 PM, Me : Looks delicious 😋
Jan 1, 2025 at 12:00 AM, Me : Happy new year!
Jan 1, 2025 at 12:01 AM, Mina Kim : Happy new year to you too 🙏
Jan 1, 2025 at 12:02 AM, Mina Kim : Video
Mar 2, 2025 at 9:30 PM, Mina Kim : Let's move to Burumy! We can bring our chats too
Mar 2, 2025 at 9:31 PM, Me : Great, I'll export our KakaoTalk chat
''';

/// The sample export as a picked file would arrive: (name, bytes).
(String, Uint8List) demoImportFile(bool ko, List<int> photo) {
  final a = Archive();
  final text = utf8.encode(_kakaoText(ko));
  a.addFile(ArchiveFile('Talk_2025.3.2 21:40-1.txt', text.length, text));
  a.addFile(ArchiveFile('KakaoTalk_20241224_190612345.png', photo.length, photo));
  return ('KakaoTalk_Chats_2025-03-02.zip', Uint8List.fromList(ZipEncoder().encode(a)));
}

/// Brings the sample into 김민지's chat (as the importer would) and offers
/// it on the guide page.
Future<void> addImportSample(FakeBackend b, bool ko, List<int> photo) async {
  ImportDemo.sample = () => demoImportFile(ko, photo);
  final (name, bytes) = demoImportFile(ko, photo);
  final bundle = ChatImport.read(name, bytes);
  final chat = bundle.chats.single;
  final me = ko ? '나' : 'Me';
  final peer = chat.people.firstWhere((x) => x != me);
  await ImportSender(b).send(
    '!r0',
    ImportChoice(chat: chat, files: bundle.files, me: me, peer: peer, peerId: '@mina:test'),
    myId: '@me:test',
  );
  // The import line sits before today's messages.
  final l = b.rooms['!r0']!;
  final card = l.removeLast();
  l.insert(0, card);
}
