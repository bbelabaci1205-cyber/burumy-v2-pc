// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > Chat folders: suggested folder, colour tag in the list,
// delete with 5-second undo, kinds that leave chats out.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_folders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<void> reveal(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).first);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('folders page: suggest, colour tag, delete + undo (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('@bob:test');
    await fake.createGroup('우리 팀', ['@mina:test']);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('folders-row')));
    await t.tap(find.byKey(const Key('folders-row')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('folders-all')), findsOneWidget);

    // Suggested "개인" folder: 1:1 chats only.
    await t.tap(find.byKey(const Key('suggest-add-personal')));
    await t.pumpAndSettle();
    expect(foldersOf(state).single.name, '개인');
    expect(find.byKey(const Key('suggest-personal')), findsNothing);
    final id = foldersOf(state).single.id;
    expect(find.text('대화방 1개'), findsOneWidget);

    // Open it, pick a colour, leave out muted chats.
    await t.tap(find.byKey(Key('folder-row-$id')));
    await t.pumpAndSettle();
    expect(find.text('태그 없음'), findsOneWidget);
    await reveal(t, find.byKey(const Key('folder-color-2')));
    await t.tap(find.byKey(const Key('folder-color-2')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('folder-tag-preview')), findsOneWidget);
    expect(find.text('태그 없음'), findsNothing);
    await reveal(t, find.byKey(const Key('folder-add-exclude')));
    await t.tap(find.byKey(const Key('folder-add-exclude')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pick-kind-muted')));
    await t.tap(find.byKey(const Key('pick-done')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('folder-kind-muted')), findsOneWidget);
    await t.tap(find.byKey(const Key('folder-save')));
    await t.pumpAndSettle();
    final f = foldersOf(state).single;
    expect(f.color, 2);
    expect(f.skip, {'muted'});

    // Delete in edit mode, then undo within 5 seconds.
    await t.tap(find.byKey(const Key('folders-edit')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('folder-minus-$id')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('folders-undo-bar')), findsOneWidget);
    expect(find.byKey(Key('folder-row-$id')), findsNothing);
    await t.tap(find.byKey(const Key('folders-undo')));
    await t.pump(const Duration(seconds: 6));
    expect(foldersOf(state), hasLength(1));
    expect(find.byKey(Key('folder-row-$id')), findsOneWidget);
    await t.tap(find.byKey(const Key('folders-done')));
    await t.pumpAndSettle();

    // The tag shows under bob's row in the chat list.
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('folder-tags-row')), findsOneWidget);
    // Switched off: gone.
    await state.setOn('folder_tags', false);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('folder-tags-row')), findsNothing);

    // Delete for real: gone after 5 seconds.
    await state.setOn('folder_tags', true);
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('folders-row')));
    await t.tap(find.byKey(const Key('folders-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('folders-edit')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('folder-minus-$id')));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    await t.pumpAndSettle();
    expect(foldersOf(state), isEmpty);
    state.stopLive();
  });

  test('folder kinds: contacts / non-contacts, skip read and archived', () {
    final f = ChatFolder(id: 'x', name: 'x', kinds: {'contacts'}, skip: {'read'});
    expect(f.label, 'x');
    f.emoji = '💼';
    expect(f.label, '💼 x');
    final back = ChatFolder.fromJson(f.toJson());
    expect(back.emoji, '💼');
    expect(back.skip, {'read'});
    expect(back.color, -1);
  });
}
