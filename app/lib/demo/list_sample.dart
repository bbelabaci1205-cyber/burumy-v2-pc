// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo: three photos in a row in the 가족 chat, so the list shows
// its small pictures (Telegram tip 59) and they fan out on a long press.
import '../core/backend.dart';
import 'demo_backend.dart';

void addListSample(FakeBackend b, List<int> photo, List<int> still) {
  final room = b.rooms['!r3'];
  if (room == null || room.isEmpty) return;
  final last = room.last;
  final files = [photo, still, photo];
  for (var i = 0; i < files.length; i++) {
    final id = 'fam-pic-$i';
    room.add(
      Msg(
        id: id,
        sender: last.sender,
        body: 'photo.jpg',
        time: last.time.add(Duration(seconds: 20 * (i + 1))),
        mine: false,
        kind: 'image',
      ),
    );
    b.files[id] = files[i];
  }
  // 목록에 사진 보이기 on, so the pictures show.
  b.prefs['list_media'] = '1';
}
