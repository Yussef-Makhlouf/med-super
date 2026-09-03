import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_cost_estimate.dart';

void main() {
  test('LabCostEstimate stores all fields', () {
    const estimate = LabCostEstimate(
      testsEstimate: 400,
      homeFee: 50,
      total: 450,
    );

    expect(estimate.testsEstimate, 400);
    expect(estimate.homeFee, 50);
    expect(estimate.total, 450);
  });

  test('homeFee is 0 when service type is a branch visit', () {
    const estimate = LabCostEstimate(
      testsEstimate: 400,
      homeFee: 0,
      total: 400,
    );

    expect(estimate.homeFee, 0);
    expect(estimate.total, estimate.testsEstimate);
  });
}
