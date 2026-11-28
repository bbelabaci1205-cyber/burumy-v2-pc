// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 읽기 모드 (Telegram tip 475, "Instant View"): a web page turned into a
// clean article (title, words, pictures) inside the app. Telegram builds
// these on its own servers, so Telegram sees which page you read; here the
// phone fetches the page itself, like a browser would, and picks the
// article out on the phone. No Burumy server is involved and nothing about
// the page is stored anywhere but in this screen.
//
// The picking is our own simple rule set (read 2026-11-27: the HTML living
// standard for element meanings, Open Graph protocol for og:title /
// og:site_name / og:image): drop menus, ads and scripts, find the part of the
// page with the most paragraph text, keep its headings, paragraphs, quotes,
// lists, code and pictures in order.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

/// One piece of an article, in reading order.
class ArticleBlock {
  const ArticleBlock(this.kind, this.text, {this.src});

  /// "h" (heading), "p", "quote", "li", "code" or "img".
  final String kind;
  final String text;

  /// Picture address (kind "img").
  final String? src;
}

class Article {
  const Article({required this.url, required this.site, required this.title, this.byline, this.image, required this.blocks});
  final String url;
  final String site;
  final String title;
  final String? byline;

  /// The page's own cover picture (og:image), if any.
  final String? image;
  final List<ArticleBlock> blocks;

  /// All the words, for the AI summary.
  String get text => blocks.where((b) => b.kind != 'img').map((b) => b.text).join('\n');

  /// Reading time in minutes (Korean ~500 letters a minute, else ~230 words).
  int get minutes {
    final t = text;
    final hangul = RegExp(r'[\uAC00-\uD7A3]').allMatches(t).length;
    final m = hangul > t.length / 4 ? t.replaceAll(RegExp(r'\s'), '').length / 500 : t.split(RegExp(r'\s+')).length / 230;
    return m < 1 ? 1 : m.round();
  }
}

class Reader {
  const Reader._();

  /// Tests and the look-only web demo answer here (the browser may not
  /// fetch other sites: CORS).
  static Future<Article?> Function(String url)? debug;

  /// Pages bigger than this are not read (a phone on mobile data).
  static const maxBytes = 3 * 1024 * 1024;

  /// Sites that are videos or app feeds, not articles: no button.
  static const _skip = [
    'youtube.com',
    'youtu.be',
    'instagram.com',
    'tiktok.com',
    'x.com',
    'twitter.com',
    'facebook.com',
    'threads.net',
    'maps.google.com',
    'map.naver.com',
    'map.kakao.com',
    'open.kakao.com',
    'apps.apple.com',
    'play.google.com',
  ];

  /// Whether to offer 읽기 모드 for [url] here.
  static bool offered(String url) {
    if (debug == null && kIsWeb) return false;
    final u = Uri.tryParse(url);
    if (u == null || (u.scheme != 'https' && u.scheme != 'http') || u.host.isEmpty) return false;
    final host = u.host.toLowerCase();
    if (_skip.any((h) => host == h || host.endsWith('.$h'))) return false;
    // A file, not a page.
    return !RegExp(r'\.(pdf|zip|jpg|jpeg|png|gif|webp|mp4|mov|mp3|apk|ipa)$', caseSensitive: false).hasMatch(u.path);
  }

  /// Fetches [url] on this phone and picks the article out (null = no
  /// article found or the page could not be read).
  static Future<Article?> open(String url, {http.Client? client}) async {
    final d = debug;
    if (d != null) return d(url);
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final c = client ?? http.Client();
    try {
      final req = http.Request('GET', uri)
        ..headers['Accept'] = 'text/html,application/xhtml+xml'
        // A plain phone-browser name: no Burumy mark, nothing about the person.
        ..headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36';
      final res = await c.send(req).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final type = res.headers['content-type'] ?? '';
      if (type.isNotEmpty && !type.contains('html')) return null;
      final bytes = <int>[];
      await for (final chunk in res.stream.timeout(const Duration(seconds: 20))) {
        bytes.addAll(chunk);
        if (bytes.length > maxBytes) return null;
      }
      return parse(utf8.decode(bytes, allowMalformed: true), res.request?.url ?? uri);
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  static const _drop =
      'script, style, noscript, nav, header, footer, aside, form, iframe, svg, button, select, input, template, '
      '[role=navigation], [role=banner], [role=contentinfo], [aria-hidden=true], .ad, .ads, .advert, .share, .sns, .comment, .comments, '
      '.related, .recommend, .breadcrumb, .menu, .sidebar, #comments';

  /// Picks the article out of a page (public for tests).
  static Article? parse(String source, Uri url) {
    final doc = html.parse(source);
    String? meta(String key) {
      final e = doc.querySelector('meta[property="$key"]') ?? doc.querySelector('meta[name="$key"]');
      final v = e?.attributes['content']?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    final site = meta('og:site_name') ?? url.host.replaceFirst(RegExp(r'^www\.'), '');
    var title = meta('og:title') ?? doc.querySelector('title')?.text.trim() ?? '';
    final h1 = doc.querySelector('article h1, main h1, h1')?.text.trim();
    if (title.isEmpty && h1 != null) title = h1;
    final byline = meta('author') ?? meta('article:author');
    final cover = meta('og:image');

    for (final e in doc.querySelectorAll(_drop)) {
      e.remove();
    }
    final body = doc.body;
    if (body == null) return null;

    // The element whose own paragraphs hold the most words.
    dom.Element? best;
    var bestScore = 0.0;
    final scores = <dom.Element, double>{};
    for (final p in body.querySelectorAll('p')) {
      final n = _clean(p.text).length;
      if (n < 25) continue;
      final parent = p.parent;
      if (parent == null) continue;
      scores[parent] = (scores[parent] ?? 0) + n;
      final grand = parent.parent;
      if (grand != null) scores[grand] = (scores[grand] ?? 0) + n / 2;
    }
    scores.forEach((e, v) {
      if (v > bestScore) {
        bestScore = v;
        best = e;
      }
    });
    final article = body.querySelector('article');
    if (article != null && _clean(article.text).length > 400 && (best == null || article.contains(best!) || bestScore < 400)) best = article;
    final root = best;
    if (root == null || bestScore < 120 && root != article) return null;

    final blocks = <ArticleBlock>[];
    void add(ArticleBlock b) {
      if (b.kind != 'img' && b.text.isEmpty) return;
      // Pages often repeat the title as the first heading.
      if (blocks.isEmpty && b.kind == 'h' && b.text == title) return;
      blocks.add(b);
    }

    void walk(dom.Element e) {
      for (final c in e.children) {
        switch (c.localName) {
          case 'h1' || 'h2' || 'h3' || 'h4' || 'h5':
            add(ArticleBlock('h', _clean(c.text)));
          case 'p':
            final t = _clean(c.text);
            if (t.length >= 2) add(ArticleBlock('p', t));
            for (final img in c.querySelectorAll('img')) {
              final src = _src(img, url);
              if (src != null) add(ArticleBlock('img', _clean(img.attributes['alt'] ?? ''), src: src));
            }
          case 'blockquote':
            add(ArticleBlock('quote', _clean(c.text)));
          case 'pre':
            add(ArticleBlock('code', c.text.trimRight()));
          case 'ul' || 'ol':
            for (final li in c.querySelectorAll('li')) {
              add(ArticleBlock('li', _clean(li.text)));
            }
          case 'img':
            final src = _src(c, url);
            if (src != null) add(ArticleBlock('img', _clean(c.attributes['alt'] ?? ''), src: src));
          case 'figure' || 'picture':
            final img = c.querySelector('img');
            final src = img == null ? null : _src(img, url);
            if (src != null) add(ArticleBlock('img', _clean(c.querySelector('figcaption')?.text ?? img!.attributes['alt'] ?? ''), src: src));
          case 'br' || 'hr':
            break;
          default:
            // A div of plain words (some Korean news sites use <br> lines).
            if (c.children.isEmpty || c.children.every((x) => const ['br', 'b', 'strong', 'em', 'i', 'a', 'span'].contains(x.localName))) {
              final lines = c.innerHtml.split(RegExp(r'<br\s*/?>', caseSensitive: false));
              for (final line in lines) {
                final t = _clean(html.parseFragment(line).text ?? '');
                if (t.length >= 25) add(ArticleBlock('p', t));
              }
            } else {
              walk(c);
            }
        }
      }
    }

    walk(root);
    if (blocks.where((b) => b.kind == 'p').length < 2) return null;
    return Article(url: url.toString(), site: site, title: title.isEmpty ? site : title, byline: byline, image: _abs(cover, url), blocks: blocks);
  }

  static String _clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String? _src(dom.Element img, Uri base) {
    final raw = img.attributes['data-src'] ?? img.attributes['src'];
    if (raw == null || raw.startsWith('data:')) return null;
    final w = int.tryParse(img.attributes['width'] ?? '');
    if (w != null && w < 80) return null; // icons, counters
    return _abs(raw, base);
  }

  static String? _abs(String? raw, Uri base) {
    if (raw == null || raw.isEmpty) return null;
    final u = base.resolve(raw.trim());
    return u.scheme == 'https' || u.scheme == 'http' ? u.toString() : null;
  }
}
