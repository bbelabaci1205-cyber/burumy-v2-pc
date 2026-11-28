// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Several accounts on one phone, switched like Telegram (Eric 2026-11-27).
// One account is free; Plus includes a second, a third can be bought.
// Each account keeps its own encrypted store ("slot"); the app lock is one
// for the whole phone. The fourth lock password ("account") erases the
// accounts chosen beforehand from this phone only: their server accounts
// stay, so friends see nothing.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'app_state.dart';
import 'backend.dart';

/// Where the list of accounts is kept (keychain on phones).
abstract class AccountBookStore {
  Future<String?> read();
  Future<void> write(String json);
}

class MemoryBookStore implements AccountBookStore {
  String? json;
  @override
  Future<String?> read() async => json;
  @override
  Future<void> write(String j) async => json = j;
}

class AccountEntry {
  AccountEntry(this.slot, this.userId);
  final int slot;
  final String userId;
  Map<String, Object> toJson() => {'slot': slot, 'user': userId};
}

class Accounts extends ChangeNotifier {
  Accounts({required this.store, required this.openSlot, required this.eraseSlot, required this.makeState, this.onShown});

  /// At most three accounts on one phone (Telegram).
  static const most = 3;

  /// TEST ONLY until payments open: lets testers add accounts without
  /// buying (Plus / one-off purchase opens 3–6 months after launch).
  /// MUST be false in launch builds.
  static bool testOpen = const bool.fromEnvironment('BURUMY_ACCOUNTS_TEST', defaultValue: true);

  final AccountBookStore store;
  final Future<Backend> Function(int slot) openSlot;

  /// Removes what this phone keeps for a slot (its store and login).
  final Future<void> Function(int slot) eraseSlot;
  final AppState Function(Backend b) makeState;

  /// Called with the state that is now on screen (after a switch).
  final Future<void> Function(AppState s)? onShown;

  /// Logged-in accounts, in the order they were added.
  List<AccountEntry> list = [];

  /// The slot on screen.
  int active = 0;

  /// Slots erased by the account password.
  Set<int> toErase = {};

  /// Bought extra accounts (store purchase, later) and Plus (includes one).
  int bought = 0;
  bool plus = false;

  /// Slot to go back to when adding an account is cancelled.
  int? _back;

  late AppState state;

  /// Other accounts, open in the background (notifications, badges).
  final side = <int, Backend>{};

  int get limit => math.min(most, 1 + (plus ? 1 : 0) + bought + (testOpen ? most : 0));
  bool get canAdd => list.length < limit;
  bool get adding => _back != null;
  List<AccountEntry> get others => [
    for (final e in list)
      if (e.slot != active) e,
  ];

  /// The account password is offered only with two or more accounts.
  bool get several => list.length >= 2;

  Future<void> _save() => store.write(
    jsonEncode({
      'accounts': [for (final e in list) e.toJson()],
      'active': active,
      'erase': toErase.toList(),
      'bought': bought,
      'plus': plus,
    }),
  );

  /// Reads the list and opens the account on screen (and the others in the
  /// background).
  Future<AppState> load() async {
    final raw = await store.read();
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        list = [for (final e in (j['accounts'] as List? ?? const [])) AccountEntry(e['slot'] as int, e['user'] as String)];
        active = j['active'] as int? ?? 0;
        toErase = {...(j['erase'] as List? ?? const []).cast<int>()};
        bought = j['bought'] as int? ?? 0;
        plus = j['plus'] as bool? ?? false;
      } catch (_) {}
    }
    final b = await openSlot(active);
    state = makeState(b)..accounts = this;
    // An older install: the one logged-in account is slot 0.
    if (list.isEmpty && b.loggedIn && b.userId != null) {
      list = [AccountEntry(active, b.userId!)];
      await _save();
    }
    for (final e in others) {
      try {
        side[e.slot] = await openSlot(e.slot);
      } catch (_) {}
    }
    return state;
  }

  Future<void> _show(Backend b) async {
    state.stopLive();
    state = makeState(b)..accounts = this;
    await _save();
    notifyListeners();
    await onShown?.call(state);
  }

  /// Puts another account on screen.
  Future<void> switchTo(int slot) async {
    if (slot == active) return;
    side[active] = state.backend;
    final b = side.remove(slot) ?? await openSlot(slot);
    active = slot;
    await _show(b);
  }

  /// "계정 추가": an empty slot goes on screen with the sign-in page.
  /// False when the limit is reached (needs Plus or a purchase).
  Future<bool> startAdd() async {
    if (!canAdd || adding) return false;
    final used = {for (final e in list) e.slot, active, ...side.keys};
    final slot = List.generate(most + 1, (i) => i).firstWhere((i) => !used.contains(i));
    await eraseSlot(slot);
    _back = active;
    side[active] = state.backend;
    active = slot;
    await _show(await openSlot(slot));
    return true;
  }

  /// Back to the account I came from, forgetting the empty slot.
  Future<void> cancelAdd() async {
    final back = _back;
    if (back == null) return;
    _back = null;
    final slot = active;
    state.stopLive();
    await eraseSlot(slot);
    active = back;
    await _show(side.remove(back) ?? await openSlot(back));
  }

  /// After a sign-in on screen. False (and signed out again) when that
  /// account is already on this phone.
  Future<bool> noteLogin() async {
    final me = state.backend.userId;
    if (me == null) return true;
    if (list.any((e) => e.userId == me && e.slot != active)) {
      try {
        await state.backend.logout();
      } catch (_) {}
      await cancelAdd();
      return false;
    }
    list = [...list.where((e) => e.slot != active), AccountEntry(active, me)];
    _back = null;
    await _save();
    notifyListeners();
    return true;
  }

  /// After "로그아웃": this account leaves the phone; another one (if
  /// any) comes on screen.
  Future<void> afterLogout() async {
    final gone = active;
    list = list.where((e) => e.slot != gone).toList();
    toErase.remove(gone);
    if (list.isEmpty) {
      await _save();
      notifyListeners();
      return;
    }
    active = list.first.slot;
    await _show(side.remove(active) ?? await openSlot(active));
    await eraseSlot(gone);
  }

  Future<void> setToErase(Set<int> slots) async {
    // Never every account: one must stay to open.
    toErase = slots.where((s) => list.any((e) => e.slot == s)).toSet();
    if (toErase.length >= list.length) toErase = toErase.skip(1).toSet();
    await _save();
    notifyListeners();
  }

  /// The account password was typed: the chosen accounts leave this phone
  /// quietly (signed out here, their stores erased). Their server accounts
  /// stay, so friends see nothing; they can sign in again elsewhere.
  Future<void> eraseChosen() async {
    final chosen = toErase.where((s) => list.any((e) => e.slot == s)).toSet();
    if (chosen.isEmpty || chosen.length >= list.length) return;
    if (chosen.contains(active)) {
      final keep = list.firstWhere((e) => !chosen.contains(e.slot)).slot;
      side[active] = state.backend;
      active = keep;
      state.stopLive();
      state = makeState(side.remove(keep) ?? await openSlot(keep))..accounts = this;
    }
    for (final slot in chosen) {
      final b = side.remove(slot) ?? await openSlot(slot);
      await _quietlyRemove(b);
      await eraseSlot(slot);
    }
    list = list.where((e) => !chosen.contains(e.slot)).toList();
    toErase = {};
    await _save();
    notifyListeners();
  }

  Future<void> _quietlyRemove(Backend b) async {
    try {
      await b.eraseEverything();
    } catch (_) {}
    try {
      await b.logout().timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Hide / delete passwords act on every account on the phone.
  Future<void> startSessionOthers(String role) async {
    for (final b in side.values) {
      try {
        await b.startSession(role);
      } catch (_) {}
    }
  }

  /// Too many wrong tries: every account's chats go, not only the one on
  /// screen.
  Future<void> eraseOthers() async {
    for (final b in side.values) {
      try {
        await b.eraseEverything();
      } catch (_) {}
    }
  }

  /// A push wake-up: the other accounts fetch too (and show notices while
  /// the app is in the background).
  Future<void> wakeOthers({required bool notify}) async {
    for (final b in side.values) {
      if (!b.loggedIn) continue;
      try {
        await b.sync(wait: Duration.zero);
        if (notify) await AppState.showNotices?.call(b);
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Unread chats of another account (its badge in the list).
  Future<int> unreadOf(int slot) async {
    final b = side[slot];
    if (b == null || !b.loggedIn) return 0;
    try {
      return (await b.chats()).where((c) => c.unread > 0).length;
    } catch (_) {
      return 0;
    }
  }

  String nameOf(AccountEntry e) => e.userId;

  @visibleForTesting
  Backend? sideOf(int slot) => side[slot];
}
