// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'dart:typed_data';

import 'phone.dart';

Future<GeoFix> location() async => throw const PhoneError('unavailable');

(double, double) safeInsets() => (0, 0);

void pageColor(String css) {}
Future<String> share(String? text, List<int>? bytes, String name, String mime, {bool saveOnly = false}) async => 'failed';
Future<List<Uint8List>> videoFrames(Uint8List video, String mime, int count, int height) async => const [];
