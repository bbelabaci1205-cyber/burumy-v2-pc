// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Scam link warnings (Settings > Chats > AI features), checked only on this
// phone: number-only hosts, punycode look-alikes, link shorteners, and names
// of well-known services on someone else's domain.
final _url = RegExp(r'(?:https?://|www\.)[^\s<>"]+', caseSensitive: false);

const _shorteners = {
  'bit.ly',
  'tinyurl.com',
  'han.gl',
  'me2.do',
  'vo.la',
  'url.kr',
  'is.gd',
  'buly.kr',
  'c11.kr',
  'cutt.ly',
  'shorturl.at',
  'rb.gy',
  't.ly',
  'goo.gl',
  'ow.ly',
};

/// Brand word -> its real domains.
const _brands = {
  'naver': ['naver.com', 'naver.me'],
  'kakao': ['kakao.com', 'kakaocorp.com', 'kakaobank.com', 'kakaopay.com'],
  'toss': ['toss.im', 'tossbank.com'],
  'coupang': ['coupang.com'],
  'apple': ['apple.com', 'icloud.com'],
  'icloud': ['icloud.com'],
  'google': ['google.com', 'google.co.kr', 'goo.gl', 'youtube.com'],
  'paypal': ['paypal.com'],
  'kbstar': ['kbstar.com'],
  'shinhan': ['shinhan.com'],
  'wooribank': ['wooribank.com'],
  'hanabank': ['hanabank.com'],
  'nhbank': ['nonghyup.com', 'nhbank.com'],
  'epost': ['epost.go.kr'],
  'cjlogistics': ['cjlogistics.com'],
  'burumy': ['burumy.app', 'burumy.com'],
  'instagram': ['instagram.com'],
  'facebook': ['facebook.com'],
  'microsoft': ['microsoft.com', 'live.com', 'office.com'],
  'amazon': ['amazon.com', 'amazon.co.jp'],
  'netflix': ['netflix.com'],
};

/// Same letters after common swaps (0 -> o, 1 -> l, rn -> m ...).
String _plain(String s) => s.replaceAll('0', 'o').replaceAll('1', 'l').replaceAll('3', 'e').replaceAll('5', 's').replaceAll('rn', 'm').replaceAll('vv', 'w');

/// Why a link looks unsafe, or null when it looks fine.
String? suspicious(String link) {
  var s = link.trim();
  if (!s.toLowerCase().startsWith('http')) s = 'https://$s';
  final u = Uri.tryParse(s);
  if (u == null || u.host.isEmpty) return null;
  final host = u.host.toLowerCase();
  if (u.userInfo.isNotEmpty) return 'userinfo';
  if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host) || host.contains(':')) return 'ip';
  if (host.split('.').any((p) => p.startsWith('xn--'))) return 'punycode';
  if (_shorteners.contains(host)) return 'short';
  final plain = _plain(host);
  for (final e in _brands.entries) {
    if (!plain.contains(e.key)) continue;
    final real = e.value.any((d) => host == d || host.endsWith('.$d'));
    if (!real) return 'lookalike';
  }
  return null;
}

/// True when any link in [text] looks unsafe.
bool hasSuspiciousLink(String text) => _url.allMatches(text).any((m) => suspicious(m.group(0)!) != null);
