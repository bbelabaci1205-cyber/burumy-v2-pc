// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Switches for features whose place is kept but which are off for now.
// Turning one on must not need screens or data to be rebuilt.

class Features {
  const Features._();

  /// Business accounts: a company owns its members' accounts and has an
  /// admin console. Engine side: engine/src/org.rs (BUSINESS_ENABLED).
  /// Eric 2026-11-23: space only, free at launch, paid tier later.
  static const business = false;

  /// Cloud AI: off. On-device AI is the rule (nothing leaves the phone).
  /// If ever switched on, it works only in chats where the user turned it
  /// on themselves, and the chat shows that it is on. Eric 2026-11-23.
  static const cloudAi = false;

  /// Friend feed (photos / words for 1:1 friends only, no ads, end-to-end
  /// encrypted, likes seen only by the poster). Built and hidden: Eric
  /// 2026-11-24 "만들고 빼고 시기를 보자". A build can turn it on with
  /// --dart-define=BURUMY_FEED=true; tests set it directly.
  static bool feed = const bool.fromEnvironment('BURUMY_FEED');
}

/// Where an AI job may run. Everything is [onDevice] while
/// [Features.cloudAi] is off. Plan (Eric picked option B, 2026-11-23):
/// phase 1 after launch, phase 2 when Plus opens.
enum AiPlace { onDevice, cloud }

/// Cloud only when: the app switch is on, the user turned it on for this
/// chat, and the chat's owner has not blocked cloud AI for the chat.
AiPlace aiPlaceFor({required bool chatAllowsCloud, bool ownerBlocksCloud = false}) =>
    Features.cloudAi && chatAllowsCloud && !ownerBlocksCloud ? AiPlace.cloud : AiPlace.onDevice;
