import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/features/motion/android_motion_input.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> sample({
    double x = -4,
    double y = 0,
    double z = 8.95,
    int rotation = 0,
  }) => {'available': true, 'x': x, 'y': y, 'z': z, 'rotation': rotation};

  test('portrait sensor axes point to the physically lower board side', () {
    final right = AndroidMotionInput.decode(sample())!;
    final left = AndroidMotionInput.decode(sample(x: 4))!;
    final down = AndroidMotionInput.decode(sample(x: 0, y: 4))!;
    final up = AndroidMotionInput.decode(sample(x: 0, y: -4))!;
    expect(right.x, greaterThan(0));
    expect(left.x, lessThan(0));
    expect(down.y, greaterThan(0));
    expect(up.y, lessThan(0));
    final flat = AndroidMotionInput.decode(sample(x: 0, y: 0, z: 9.80665))!;
    expect(flat.length, 0);
  });

  test(
    'natural landscape devices remap all display rotations consistently',
    () {
      for (final item in [
        (0, -4.0, 0.0),
        (1, 0.0, 4.0),
        (2, 4.0, 0.0),
        (3, 0.0, -4.0),
      ]) {
        final tilt = AndroidMotionInput.decode(
          sample(rotation: item.$1, x: item.$2, y: item.$3),
        )!;
        expect(tilt.x, closeTo(4 / 9.80665, 1e-6));
        expect(tilt.y, closeTo(0, 1e-6));
      }
      expect(
        AndroidMotionInput.decode(sample(x: -15, y: 15, z: 0))!.length,
        closeTo(1, 1e-6),
      );
    },
  );

  test(
    'missing, nonfinite, invalid or zero readings never claim compatibility',
    () {
      for (final payload in [
        null,
        {},
        {'available': false},
        sample(x: double.nan),
        sample(y: double.infinity),
        sample(x: 0, y: 0, z: 0),
        sample(z: 500),
        sample(rotation: 8),
        {...sample(), 'x': 'not a reading'},
      ]) {
        expect(AndroidMotionInput.decode(payload), isNull);
      }
    },
  );

  test(
    'hardware probe must succeed; unavailable or missing native APIs safely disable events',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          AndroidMotionInput.control,
          null,
        ),
      );
      for (final available in [false, true]) {
        messenger.setMockMethodCallHandler(AndroidMotionInput.control, (
          call,
        ) async {
          expect(call.method, 'probe');
          return {'available': available};
        });
        final input = AndroidMotionInput(androidSupported: true);
        await input.initialize();
        expect(input.available, available);
        input.dispose();
      }
      messenger.setMockMethodCallHandler(
        AndroidMotionInput.control,
        (call) async => throw PlatformException(code: 'no_sensor'),
      );
      final unavailable = AndroidMotionInput(androidSupported: true);
      await unavailable.initialize();
      expect(unavailable.available, isFalse);
      unavailable.dispose();
      var called = false;
      messenger.setMockMethodCallHandler(AndroidMotionInput.control, (
        call,
      ) async {
        called = true;
        return {'available': true};
      });
      final otherPlatform = AndroidMotionInput(androidSupported: false);
      await otherPlatform.initialize();
      otherPlatform.setActive(true);
      expect(otherPlatform.available, isFalse);
      expect(called, isFalse);
      otherPlatform.dispose();
    },
  );

  testWidgets(
    'only fresh stream samples drive tilt; pause, errors and timeout reset force',
    (tester) async {
      final samples = StreamController<dynamic>.broadcast();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        AndroidMotionInput.control,
        (call) async => {'available': true},
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          AndroidMotionInput.control,
          null,
        ),
      );
      final input = AndroidMotionInput(
        androidSupported: true,
        samples: samples.stream,
      );
      await input.initialize();
      input.setActive(true);
      expect(input.tilt.length, 0);
      samples.add(sample());
      await tester.pump();
      expect(input.available, isTrue);
      expect(input.tilt.x, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(input.available, isFalse);
      expect(input.tilt.length, 0);
      samples.add(sample(y: 3));
      await tester.pump();
      expect(input.available, isTrue);
      input.setActive(false);
      expect(input.tilt.length, 0);
      samples.add(sample(x: 5));
      await tester.pump();
      expect(input.tilt.length, 0);
      input.setActive(true);
      samples.addError(StateError('sensor disconnected'));
      await tester.pump();
      expect(input.available, isFalse);
      expect(input.tilt.length, 0);
      samples.add(sample());
      await tester.pump();
      expect(input.available, isTrue);
      samples.add(sample(x: double.nan));
      await tester.pump();
      expect(input.available, isFalse);
      input.dispose();
      await samples.close();
      await tester.pump();
      expect(input.available, isFalse);
    },
  );

  testWidgets(
    'an unresponsive stream loses availability without repeated activation attempts',
    (tester) async {
      final samples = StreamController<dynamic>.broadcast();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        AndroidMotionInput.control,
        (call) async => {'available': true},
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          AndroidMotionInput.control,
          null,
        ),
      );
      final input = AndroidMotionInput(
        androidSupported: true,
        samples: samples.stream,
      );
      await input.initialize();
      input.setActive(true);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(input.available, isFalse);
      input.dispose();
      await samples.close();
    },
  );
}
