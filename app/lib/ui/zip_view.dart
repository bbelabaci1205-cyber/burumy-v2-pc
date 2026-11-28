// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// ZIP 미리보기 (4-app board): a received ZIP shows what's inside, grouped
// by folder; tap a file to open just that one (in memory, through the same
// viewer as other files). Nothing is written to the phone's disk.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../core/backend.dart';
import '../core/open_docs.dart';
import '../core/phone.dart';
import '../core/storage_usage.dart';
import '../core/zip_peek.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'file_viewer.dart' show FileTile, FileViewerPage, mimeOfName;
import 'stories.dart' show showStoryToast;
import 'ios.dart';
import 'ios_route.dart';

class ZipView extends StatefulWidget {
  const ZipView({super.key, required this.doc, required this.fallback});
  final OpenDoc doc;

  /// Shown when it can't be looked inside (the usual 다른 앱으로 열기 card).
  final Widget Function(BuildContext context) fallback;

  @override
  State<ZipView> createState() => _ZipViewState();
}

class _ZipViewState extends State<ZipView> {
  late final ZipPeekResult r = ZipPeek.list(widget.doc.name, widget.doc.bytes);

  Future<void> open(ZipEntry e) async {
    final l = L.of(context);
    final bytes = ZipPeek.read(widget.doc.name, widget.doc.bytes, e);
    if (bytes == null) return showStoryToast(context, e.size > ZipPeek.maxUnpacked ? l.zipTooBig : l.zipCantOpen);
    final kind = fileKindOf(e.name);
    if (!opensInApp(kind)) {
      // Not drawn here: in a protected chat it stays in; else other apps.
      if (widget.doc.protected) return showStoryToast(context, l.docProtectedNoShare);
      await Phone.share(bytes: bytes, name: e.name, mime: mimeOfName(e.name));
      return;
    }
    final m = widget.doc.msg;
    final inner = OpenDoc(
      roomId: widget.doc.roomId,
      msg: Msg(id: '${m.id}#${e.path}', sender: m.sender, body: e.name, time: m.time, mine: m.mine, kind: 'file', size: bytes.length),
      bytes: Uint8List.fromList(bytes),
      chat: widget.doc.chat,
      protected: widget.doc.protected,
    );
    await Navigator.of(context).push(IosPageRoute(builder: (_) => FileViewerPage(doc: inner)));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    if (r.problem == ZipProblem.password) return _note(context, l.zipPassword);
    if (r.problem == ZipProblem.broken || r.problem == ZipProblem.unsupported) return widget.fallback(context);
    if (r.entries.isEmpty) return _note(context, l.zipEmpty);
    // Folder → files, top-level files first.
    final by = <String, List<ZipEntry>>{};
    for (final e in r.entries) {
      (by[e.folder] ??= []).add(e);
    }
    final folders = by.keys.toList()..sort((a, b) => a.isEmpty ? -1 : (b.isEmpty ? 1 : a.compareTo(b)));
    return ListView(
      key: const Key('zip-list'),
      padding: EdgeInsets.only(top: Tokens.space[1], bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[5]),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], Tokens.space[2]),
          child: Text(
            [
              l.zipCount(r.total),
              l.zipUnpacked(sizeText(ZipPeek.sizeOf(r.entries))),
              if (r.problem == ZipProblem.tooMany) l.zipFirstOnly(ZipPeek.maxEntries),
            ].join(' · '),
            key: const Key('zip-summary'),
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
        ),
        for (final f in folders)
          IosSection(
            header: f.isEmpty ? null : Text(f, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            children: [
              for (final e in by[f]!)
                IosTile(
                  key: Key('zip-${e.path}'),
                  leading: FileTile(name: e.name, size: 32),
                  title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  additionalInfo: Text(sizeText(e.size)),
                  trailing: const IosChevron(),
                  onTap: () => unawaited(open(e)),
                ),
            ],
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], 0),
          child: Text(l.zipInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ],
    );
  }

  Widget _note(BuildContext context, String text) {
    final p = paletteOf(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Tokens.space[4]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FileTile(name: widget.doc.name, size: 72),
            SizedBox(height: Tokens.space[3]),
            Text(text, key: const Key('zip-note'), textAlign: TextAlign.center, style: Tokens.body.style.copyWith(color: p.label)),
          ],
        ),
      ),
    );
  }
}
