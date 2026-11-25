// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Profile card: photo / about me / birthday shared by the 공개 범위 choices.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves here and shares by who-choices; friends get a card', () async {
    final fake = FakeBackend();
    final s = AppState(fake);
    await fake.login(id: 'me', password: 'x');
    await s.refresh();
    await s.saveMyProfile(photo: [1, 2, 3], bio: '안녕', birthday: '03-14');
    expect(s.pref('me_birthday', ''), '03-14');
    expect(s.myOwnPhoto, [1, 2, 3]);
    // Defaults: photo + about me for everyone, birthday for contacts.
    expect(fake.shared, {'photo': 'everyone', 'bio': 'everyone', 'birthday': 'contacts', 'birthdayValue': '03-14'});
    expect(fake.photo, [1, 2, 3]);
    await s.setPref('who_photo', 'contacts');
    await s.publishProfile();
    expect(fake.photo, isNull, reason: 'friends-only photo is not public');
    expect(s.myOwnPhoto, [1, 2, 3], reason: 'still shown on my own phone');
    fake.cards['@kim:x'] = const ProfileCard(photo: [9], bio: 'hi', birthday: '12-25', private: true);
    s.cardOf('@kim:x');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(s.cardOf('@kim:x')?.birthday, '12-25');
    expect(s.cardPhoto('@kim:x'), [9]);
  });
}
