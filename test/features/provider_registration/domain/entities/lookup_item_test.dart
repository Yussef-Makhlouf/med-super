import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_registration/domain/entities/lookup_item.dart';

void main() {
  group('LookupItem', () {
    test('stores id and label as given', () {
      const item = LookupItem(id: 'cardio', label: 'Cardiology');

      expect(item.id, 'cardio');
      expect(item.label, 'Cardiology');
    });

    test(
      'two non-const instances built from the same values expose the same fields',
      () {
        final id = 'x-${DateTime.now().microsecondsSinceEpoch}';
        final a = LookupItem(id: id, label: 'X');
        final b = LookupItem(id: id, label: 'X');

        // No custom equality (==) is defined on LookupItem, so two distinct
        // non-const instances are not `==` to each other even though every
        // field matches — this documents that current behavior rather than
        // relying on const-canonicalization (which would make them literally
        // the same object and equal by identity).
        expect(identical(a, b), isFalse);
        expect(a == b, isFalse);
        expect(a.id, b.id);
        expect(a.label, b.label);
      },
    );
  });
}
