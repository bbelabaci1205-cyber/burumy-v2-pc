// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 자세한 신고 (Telegram tip 478, Eric 2026-11-27 "다해죠"): a reason, then a
// narrower reason, then an optional note. Every pick has a stable code
// (like "goods.weapons") so the operator page can sort and count reports
// whatever language the reporter's phone uses. Only the one reported
// message goes to the operator (rule D1), as before.

/// One reason on the first or second step.
class ReportReason {
  const ReportReason(this.code, [this.subs = const []]);

  /// Stable code: "group" on the first step, "group.sub" on the second.
  final String code;
  final List<ReportReason> subs;

  String get group => code.split('.').first;
}

class ReportReasons {
  const ReportReasons._();

  /// "그냥 싫어요": nothing goes to the operator; the app offers to hide the
  /// message on this phone or block the sender.
  static const dislike = 'dislike';

  /// 사칭: the account goes to the trust service (not the message).
  static const impersonation = 'scam.impersonation';

  /// 저작권: only the rights holder can claim it, on the web form.
  static const copyright = 'copyright';

  /// First step, most serious first (like Telegram's order, our words).
  static const all = <ReportReason>[
    ReportReason(dislike),
    ReportReason('child', [ReportReason('child.sexual'), ReportReason('child.abuse'), ReportReason('child.danger')]),
    ReportReason('sexual_crime', [
      ReportReason('sexual_crime.hidden_camera'),
      ReportReason('sexual_crime.deepfake'),
      ReportReason('sexual_crime.shared_without_consent'),
      ReportReason('sexual_crime.extortion'),
    ]),
    ReportReason('violence', [
      ReportReason('violence.threat'),
      ReportReason('violence.graphic'),
      ReportReason('violence.self_harm'),
      ReportReason('violence.hate'),
    ]),
    ReportReason('goods', [ReportReason('goods.drugs'), ReportReason('goods.weapons'), ReportReason('goods.fake_documents'), ReportReason('goods.other')]),
    ReportReason('adult', [ReportReason('adult.porn'), ReportReason('adult.unwanted')]),
    ReportReason('privacy', [ReportReason('privacy.id_documents'), ReportReason('privacy.contact'), ReportReason('privacy.photos')]),
    ReportReason('terror', [ReportReason('terror.promotion'), ReportReason('terror.recruiting')]),
    ReportReason('scam', [ReportReason('scam.phishing'), ReportReason('scam.money'), ReportReason('scam.spam'), ReportReason(impersonation)]),
    ReportReason(copyright),
    ReportReason('takedown'),
    ReportReason('other'),
  ];

  static ReportReason? find(String code) {
    for (final r in all) {
      if (r.code == code) return r;
      for (final s in r.subs) {
        if (s.code == code) return s;
      }
    }
    return null;
  }

  /// Looked at first by the operator (children, sexual crimes, terror,
  /// threats to life).
  static bool urgent(String code) {
    final g = code.split('.').first;
    return g == 'child' || g == 'sexual_crime' || g == 'terror' || code == 'violence.self_harm' || code == 'violence.threat';
  }

  /// Illegal pictures also go to the trust service in groups and channels:
  /// three reports from different (older) accounts hide the message for
  /// everyone before the operator looks.
  static bool illegalPicture(String code) {
    final g = code.split('.').first;
    return g == 'child' || g == 'sexual_crime';
  }

  /// The words sent with the Matrix report: a machine line first (code,
  /// urgent mark), then the reason as the reporter saw it, then the note.
  static String reportText({required String code, required String label, String note = ''}) {
    final n = note.trim();
    final cut = n.length > 500 ? n.substring(0, 500) : n;
    return ['burumy-report/1 code=$code${urgent(code) ? ' urgent=1' : ''}', label, if (cut.isNotEmpty) 'note: $cut'].join('\n');
  }
}
