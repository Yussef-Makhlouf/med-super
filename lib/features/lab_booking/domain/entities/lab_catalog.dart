import 'lab_test.dart';
import 'lab_test_category.dart';
import 'suggested_lab.dart';

class LabCatalog {
  const LabCatalog({
    required this.categories,
    required this.tests,
    required this.suggestedLabs,
  });

  final List<LabTestCategory> categories;
  final List<LabTest> tests;
  final List<SuggestedLab> suggestedLabs;
}
