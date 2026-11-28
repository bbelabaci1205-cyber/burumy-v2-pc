// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Public keys that may sign PC app updates (update.json -> update.json.sig).
// Only the PUBLIC half lives here; the private key stays on Eric's computer
// (made with tools/pc-update-signing/1-키만들기.bat) and nobody else has it.
// Empty list = the app never updates itself (safe default until Eric's key
// is added). To change keys later, ship a build that has BOTH the old and the
// new key, sign with the new one from then on, then drop the old one.
const updatePublicKeys = <String>[
  // 'ssh-ed25519 AAAA... burumy-update',
];
