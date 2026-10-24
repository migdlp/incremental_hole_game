import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/features/feeding/domain/feeding_progress.dart';

// Deliberately independent of dart:io fixtures so the same test runs in Chromium.
void main() {
  test('huge quota transitions and JSON stay exact on VM and JavaScript', () {
    final f = FeedingProgress(startDay: 1);
    final total = BigInt.from(10).pow(500) + BigInt.from(123456789);
    final events = f.creditBalls(1, normal: total, instant: BigInt.zero);
    final consumed = events.fold(
      BigInt.zero,
      (n, level) => n + BigInt.from(100) * BigInt.from(10).pow(level - 1),
    );
    expect(consumed + f.points, total);
    expect(f.target, BigInt.from(10).pow(500));
    expect(f.growths, events.length);
    final restored = FeedingProgress.fromJson(
      jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>,
      day: 1,
      running: true,
    );
    expect(restored.toJson(), f.toJson());
    expect(restored.credit(1, normal: 0, instant: 0), isEmpty);
    expect(restored.fraction, inInclusiveRange(0.0, 1.0));
    expect(ballNumber(f.target!), '1 ×10^500');
    expect(ballNumber(total), startsWith('≈ 1 ×10^500'));
    expect(ballNumber(BigInt.from(2450)), '2.450');
    expect(() => FeedingProgress(startDay: 1, target: 0), throwsArgumentError);
  });
}
