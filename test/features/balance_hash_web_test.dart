import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/features/balance/domain/balance_metrics.dart';

void main() {
  test(
    'canonical numeric configuration digest matches VM/web including exact BigInt',
    () {
      expect(
        configurationHash({
          'b': 2,
          'a': [1],
        }),
        '129b33e6e582b4737590f8c81bf551e8fc872ea7953ae3ac3d0b22005e0123d4',
      );
      expect(
        configurationHash({
          'b': 2.0,
          'a': [1.0],
        }),
        configurationHash({
          'a': [1],
          'b': 2,
        }),
      );
      final huge = BigInt.from(10).pow(500);
      expect(canonical(huge), huge.toString());
      expect(
        configurationHash({'quota': huge}),
        configurationHash({'quota': huge.toString()}),
      );
    },
  );
}
