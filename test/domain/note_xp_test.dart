import 'package:flutter_test/flutter_test.dart';
import 'package:babydaily/src/domain/note_xp.dart';

void main() {
  group('noteXpForStreak（当天存在 ≥20 字笔记时的经验）', () {
    test('连续第 1 天：固定 10', () {
      expect(noteXpForStreak(1), 10);
    });

    test('连续第 N 天：10 + min(N-1, 5)', () {
      expect(noteXpForStreak(2), 11);
      expect(noteXpForStreak(3), 12);
      expect(noteXpForStreak(6), 15);
    });

    test('连续超过上限天数后封顶 15', () {
      expect(noteXpForStreak(7), 15);
      expect(noteXpForStreak(100), 15);
    });

    test('当天没有合格笔记：0', () {
      expect(noteXpForStreak(0), 0);
    });
  });
}
