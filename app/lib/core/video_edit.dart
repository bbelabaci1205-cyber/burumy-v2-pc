// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 동영상 자르기·회전 (Telegram tip 56): what was chosen in the video editor
// before sending. The phone makes a new, shorter / turned video from it
// (Phone.editVideo); the cut-off parts are never sent.
class VideoEdit {
  const VideoEdit({this.start = Duration.zero, this.end, this.turns = 0, this.flip = false});

  /// Keep from [start] to [end] (null = to the end).
  final Duration start;
  final Duration? end;

  /// Quarter turns to the left (iPhone Photos 회전 button), 0–3.
  final int turns;

  /// 좌우 뒤집기 (mirror).
  final bool flip;

  static const none = VideoEdit();

  /// Shortest piece the editor lets you keep.
  static const minLength = Duration(seconds: 1);

  bool get trims => start > Duration.zero || end != null;
  bool get turnsOrFlips => turns % 4 != 0 || flip;
  bool get isNone => !trims && !turnsOrFlips;

  /// Length after the cut, for a video [full] long.
  Duration lengthOf(Duration full) {
    final e = end == null || end! > full ? full : end!;
    final d = e - start;
    return d.isNegative ? Duration.zero : d;
  }

  /// Turned sideways: width and height swap.
  bool get sideways => turns % 2 == 1;

  /// Degrees to the left (counter-clockwise), as iPhone shows them.
  int get degrees => (turns % 4) * 90;

  VideoEdit copyWith({Duration? start, Duration? end, bool clearEnd = false, int? turns, bool? flip}) =>
      VideoEdit(start: start ?? this.start, end: clearEnd ? null : (end ?? this.end), turns: (turns ?? this.turns) % 4, flip: flip ?? this.flip);

  /// What the phone's video maker gets (milliseconds, -1 = to the end).
  Map<String, Object> toChannel() => {'startMs': start.inMilliseconds, 'endMs': end?.inMilliseconds ?? -1, 'turns': turns % 4, 'flip': flip};

  @override
  bool operator ==(Object other) => other is VideoEdit && other.start == start && other.end == end && other.turns % 4 == turns % 4 && other.flip == flip;

  @override
  int get hashCode => Object.hash(start, end, turns % 4, flip);
}
