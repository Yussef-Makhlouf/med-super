enum Flavor { patient, provider }

Flavor _current = Flavor.patient;

Flavor get currentFlavor => _current;

void setFlavor(Flavor flavor) {
  _current = flavor;
}

extension FlavorX on Flavor {
  bool get isPatient => this == Flavor.patient;
  bool get isProvider => this == Flavor.provider;

  String get displayName => switch (this) {
        Flavor.patient => 'MedSuper',
        Flavor.provider => 'MedSuper Pro',
      };
}
