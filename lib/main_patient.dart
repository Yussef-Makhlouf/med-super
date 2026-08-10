import 'package:med_super/app/app.dart';
import 'package:med_super/app/flavor.dart';
import 'package:med_super/bootstrap.dart';

void main() {
  setFlavor(Flavor.patient);
  bootstrap(() => const App());
}
