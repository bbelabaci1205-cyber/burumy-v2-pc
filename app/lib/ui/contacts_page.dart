// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Contacts: people I chat with 1:1, plus finding someone by ID.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart';
import 'common.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Person> contacts = const [];
  List<Person>? found;
  Timer? _debounce;
  AppState? state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (s != state) {
      state?.removeListener(load);
      state = s..addListener(load);
      load();
    }
  }

  @override
  void dispose() {
    state?.removeListener(load);
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final c = await state!.backend.contacts();
    if (mounted) setState(() => contacts = c);
  }

  void search(String term) {
    _debounce?.cancel();
    if (term.trim().isEmpty) return setState(() => found = null);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final r = await state!.backend.searchPeople(term.trim());
      if (mounted) setState(() => found = r);
    });
  }

  Future<void> open(Person p) async {
    final room = p.roomId ?? await state!.makeChat(() => state!.backend.createDirectChat(p.userId));
    unawaited(state!.refresh());
    if (mounted) {
      await openChat(context, room, p.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final list = found ?? contacts;
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l.tabContacts, style: Tokens.largeTitle.style.copyWith(color: p.label)),
            border: null,
            backgroundColor: p.list.withValues(alpha: 0.0),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[1]),
              child: CupertinoSearchTextField(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                key: const Key('people-search'),
                placeholder: l.searchById,
                onChanged: search,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.groupTitleToCard),
              child: Text(found == null ? l.contactsSection : l.searchResults, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(found == null ? l.contactsEmpty : l.noOneFound, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
              ),
            )
          else
            SliverList.builder(
              itemCount: list.length,
              itemBuilder: (c, i) {
                final person = list[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => open(person),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                    child: Row(
                      children: [
                        Avatar(name: person.name, size: 40, userId: person.userId),
                        SizedBox(width: Tokens.space[2]),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(person.name, style: Tokens.body.style.copyWith(color: p.label)),
                              SizedBox(height: Tokens.nameToSub),
                              Text(displayId(person.userId), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
