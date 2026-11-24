// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// A small QR code maker written from the public QR standard (ISO/IEC 18004):
// byte mode, error level M, versions 1-10 (up to 213 bytes). Enough for
// "my ID" links. Returns the dark/light squares; drawing is up to the UI.
import 'dart:convert';

class QrCode {
  QrCode._(this.size, this._dark);
  final int size;
  final List<bool> _dark;

  bool dark(int x, int y) => _dark[y * size + x];

  /// null when the text is too long for version 10.
  static QrCode? encode(String text) {
    final bytes = utf8.encode(text);
    for (var v = 1; v <= 10; v++) {
      final spec = _specs[v - 1];
      final cap = spec.dataCodewords;
      final countBits = v < 10 ? 8 : 16;
      if (4 + countBits + bytes.length * 8 > cap * 8) continue;
      return _make(v, spec, bytes, countBits);
    }
    return null;
  }

  // (ec per block, [blocks, data codewords], [blocks, data codewords])
  static const _specs = [
    _Spec(10, 1, 16, 0, 0),
    _Spec(16, 1, 28, 0, 0),
    _Spec(26, 1, 44, 0, 0),
    _Spec(18, 2, 32, 0, 0),
    _Spec(24, 2, 43, 0, 0),
    _Spec(16, 4, 27, 0, 0),
    _Spec(18, 4, 31, 0, 0),
    _Spec(22, 2, 38, 2, 39),
    _Spec(22, 3, 36, 2, 37),
    _Spec(26, 4, 43, 1, 44),
  ];

  static const _align = [
    <int>[],
    [6, 18],
    [6, 22],
    [6, 26],
    [6, 30],
    [6, 34],
    [6, 22, 38],
    [6, 24, 42],
    [6, 26, 46],
    [6, 28, 50],
  ];

  static QrCode _make(int version, _Spec spec, List<int> bytes, int countBits) {
    // 1. Data bits.
    final bits = <bool>[];
    void put(int value, int n) {
      for (var i = n - 1; i >= 0; i--) {
        bits.add((value >> i) & 1 == 1);
      }
    }

    put(4, 4); // byte mode
    put(bytes.length, countBits);
    for (final b in bytes) {
      put(b, 8);
    }
    final capBits = spec.dataCodewords * 8;
    put(0, (capBits - bits.length).clamp(0, 4));
    while (bits.length % 8 != 0) {
      bits.add(false);
    }
    final data = <int>[for (var i = 0; i < bits.length; i += 8) _byte(bits, i)];
    for (var pad = 0xEC; data.length < spec.dataCodewords; pad ^= 0xEC ^ 0x11) {
      data.add(pad);
    }

    // 2. Blocks + Reed-Solomon, then interleave.
    final blocks = <List<int>>[];
    var at = 0;
    for (final (n, len) in [(spec.b1, spec.d1), (spec.b2, spec.d2)]) {
      for (var i = 0; i < n; i++) {
        blocks.add(data.sublist(at, at + len));
        at += len;
      }
    }
    final gen = _generator(spec.ec);
    final ecs = [for (final b in blocks) _remainder(b, gen)];
    final all = <int>[];
    final maxData = blocks.map((b) => b.length).reduce((a, b) => a > b ? a : b);
    for (var i = 0; i < maxData; i++) {
      for (final b in blocks) {
        if (i < b.length) all.add(b[i]);
      }
    }
    for (var i = 0; i < spec.ec; i++) {
      for (final e in ecs) {
        all.add(e[i]);
      }
    }

    // 3. Function patterns.
    final size = version * 4 + 17;
    final m = List<bool>.filled(size * size, false);
    final fn = List<bool>.filled(size * size, false);
    void set(int x, int y, bool d) {
      m[y * size + x] = d;
      fn[y * size + x] = true;
    }

    for (var i = 0; i < size; i++) {
      set(6, i, i % 2 == 0);
      set(i, 6, i % 2 == 0);
    }
    void finder(int cx, int cy) {
      for (var dy = -4; dy <= 4; dy++) {
        for (var dx = -4; dx <= 4; dx++) {
          final x = cx + dx, y = cy + dy;
          if (x < 0 || y < 0 || x >= size || y >= size) continue;
          final d = (dx.abs() > dy.abs() ? dx.abs() : dy.abs());
          set(x, y, d != 2 && d != 4);
        }
      }
    }

    finder(3, 3);
    finder(size - 4, 3);
    finder(3, size - 4);
    final al = _align[version - 1];
    for (var i = 0; i < al.length; i++) {
      for (var j = 0; j < al.length; j++) {
        if ((i == 0 && j == 0) || (i == 0 && j == al.length - 1) || (i == al.length - 1 && j == 0)) continue;
        for (var dy = -2; dy <= 2; dy++) {
          for (var dx = -2; dx <= 2; dx++) {
            final d = (dx.abs() > dy.abs() ? dx.abs() : dy.abs());
            set(al[i] + dx, al[j] + dy, d != 1);
          }
        }
      }
    }
    void format(int mask) {
      final d = (0 << 3) | mask; // level M = 00
      var rem = d;
      for (var i = 0; i < 10; i++) {
        rem = (rem << 1) ^ ((rem >> 9) * 0x537);
      }
      final f = ((d << 10) | rem) ^ 0x5412;
      bool b(int i) => (f >> i) & 1 == 1;
      for (var i = 0; i <= 5; i++) {
        set(8, i, b(i));
      }
      set(8, 7, b(6));
      set(8, 8, b(7));
      set(7, 8, b(8));
      for (var i = 9; i < 15; i++) {
        set(14 - i, 8, b(i));
      }
      for (var i = 0; i < 8; i++) {
        set(size - 1 - i, 8, b(i));
      }
      for (var i = 8; i < 15; i++) {
        set(8, size - 15 + i, b(i));
      }
      set(8, size - 8, true);
    }

    format(0); // reserve
    if (version >= 7) {
      var rem = version;
      for (var i = 0; i < 12; i++) {
        rem = (rem << 1) ^ ((rem >> 11) * 0x1F25);
      }
      final v = (version << 12) | rem;
      for (var i = 0; i < 18; i++) {
        final d = (v >> i) & 1 == 1;
        final a = size - 11 + i % 3, b = i ~/ 3;
        set(a, b, d);
        set(b, a, d);
      }
    }

    // 4. Data, zigzag from the bottom right.
    var i = 0;
    for (var right = size - 1; right >= 1; right -= 2) {
      if (right == 6) right = 5;
      for (var vert = 0; vert < size; vert++) {
        for (var j = 0; j < 2; j++) {
          final x = right - j;
          final up = ((right + 1) & 2) == 0;
          final y = up ? size - 1 - vert : vert;
          if (!fn[y * size + x] && i < all.length * 8) {
            m[y * size + x] = (all[i >> 3] >> (7 - (i & 7))) & 1 == 1;
            i++;
          }
        }
      }
    }

    // 5. Pick the mask with the lowest penalty.
    List<bool>? best;
    var bestScore = 1 << 30;
    for (var mask = 0; mask < 8; mask++) {
      final t = List<bool>.of(m);
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          if (!fn[y * size + x] && _maskBit(mask, x, y)) t[y * size + x] = !t[y * size + x];
        }
      }
      // write this mask's format bits into t
      final saved = List<bool>.of(m);
      m.setAll(0, t);
      format(mask);
      final withFormat = List<bool>.of(m);
      m.setAll(0, saved);
      final score = _penalty(withFormat, size);
      if (score < bestScore) {
        bestScore = score;
        best = withFormat;
      }
    }
    return QrCode._(size, best!);
  }

  static int _byte(List<bool> bits, int i) {
    var v = 0;
    for (var k = 0; k < 8; k++) {
      v = (v << 1) | (bits[i + k] ? 1 : 0);
    }
    return v;
  }

  static bool _maskBit(int mask, int x, int y) => switch (mask) {
    0 => (x + y) % 2 == 0,
    1 => y % 2 == 0,
    2 => x % 3 == 0,
    3 => (x + y) % 3 == 0,
    4 => (x ~/ 3 + y ~/ 2) % 2 == 0,
    5 => x * y % 2 + x * y % 3 == 0,
    6 => (x * y % 2 + x * y % 3) % 2 == 0,
    _ => ((x + y) % 2 + x * y % 3) % 2 == 0,
  };

  static int _penalty(List<bool> m, int size) {
    var score = 0;
    bool at(int x, int y) => m[y * size + x];
    for (var pass = 0; pass < 2; pass++) {
      for (var a = 0; a < size; a++) {
        var run = 1;
        final line = StringBuffer();
        for (var b = 0; b < size; b++) {
          final d = pass == 0 ? at(b, a) : at(a, b);
          line.write(d ? '1' : '0');
          if (b > 0) {
            final prev = pass == 0 ? at(b - 1, a) : at(a, b - 1);
            if (d == prev) {
              run++;
              if (run == 5) score += 3;
              if (run > 5) score += 1;
            } else {
              run = 1;
            }
          }
        }
        final s = line.toString();
        score += 40 * ('00001011101'.allMatches(s).length + '10111010000'.allMatches(s).length);
      }
    }
    for (var y = 0; y < size - 1; y++) {
      for (var x = 0; x < size - 1; x++) {
        final d = at(x, y);
        if (d == at(x + 1, y) && d == at(x, y + 1) && d == at(x + 1, y + 1)) score += 3;
      }
    }
    final darks = m.where((d) => d).length;
    final k = ((darks * 20 - m.length * 10).abs() + m.length - 1) ~/ m.length - 1;
    score += (k < 0 ? 0 : k) * 10;
    return score;
  }

  // GF(256) with 0x11D.
  static int _mul(int a, int b) {
    var r = 0;
    for (var i = 7; i >= 0; i--) {
      r = (r << 1) ^ ((r >> 7) * 0x11D);
      if ((b >> i) & 1 == 1) r ^= a;
    }
    return r & 0xFF;
  }

  static List<int> _generator(int degree) {
    final r = List<int>.filled(degree, 0)..[degree - 1] = 1;
    var root = 1;
    for (var i = 0; i < degree; i++) {
      for (var j = 0; j < degree; j++) {
        r[j] = _mul(r[j], root);
        if (j + 1 < degree) r[j] ^= r[j + 1];
      }
      root = _mul(root, 2);
    }
    return r;
  }

  static List<int> _remainder(List<int> data, List<int> gen) {
    final r = List<int>.filled(gen.length, 0, growable: true);
    for (final b in data) {
      final f = b ^ r.removeAt(0);
      r.add(0);
      for (var i = 0; i < gen.length; i++) {
        r[i] ^= _mul(gen[i], f);
      }
    }
    return r;
  }
}

class _Spec {
  const _Spec(this.ec, this.b1, this.d1, this.b2, this.d2);
  final int ec, b1, d1, b2, d2;
  int get dataCodewords => b1 * d1 + b2 * d2;
}
