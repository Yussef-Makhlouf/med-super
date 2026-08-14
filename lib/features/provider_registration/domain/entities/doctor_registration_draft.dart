import 'clinic_working_day.dart';
import 'uploaded_document.dart';

class DoctorRegistrationDraft {
  const DoctorRegistrationDraft({
    this.fullName = '',
    this.specialty,
    this.degree = '',
    this.email = '',
    this.experienceYears = 0,
    this.bio = '',
    this.profilePhotoLocalPath,
    this.profilePhotoDataUri,
    this.documents = const [],
    this.clinicName = '',
    this.clinicAddress = '',
    this.city,
    this.clinicLat,
    this.clinicLng,
    this.consultationFee = 0,
    this.workingDays = const [
      ClinicWorkingDay(day: Weekday.saturday, isEnabled: false),
      ClinicWorkingDay(day: Weekday.sunday, isEnabled: false),
      ClinicWorkingDay(day: Weekday.monday, isEnabled: false),
      ClinicWorkingDay(day: Weekday.tuesday, isEnabled: false),
      ClinicWorkingDay(day: Weekday.wednesday, isEnabled: false),
      ClinicWorkingDay(day: Weekday.thursday, isEnabled: false),
      ClinicWorkingDay(day: Weekday.friday, isEnabled: false),
    ],
    this.agreedToTerms = false,
  });

  final String fullName;
  final String? specialty;
  final String degree;
  final String email;
  final int experienceYears;
  final String bio;
  final String? profilePhotoLocalPath;

  /// Base64 `data:` URI of the actually-picked photo bytes — the app has no
  /// real file storage in mock mode, so this is what actually becomes the
  /// doctor's `avatar_url` after submission. [profilePhotoLocalPath] is only
  /// the display filename.
  final String? profilePhotoDataUri;
  final List<UploadedDocument> documents;
  final String clinicName;
  final String clinicAddress;
  final String? city;
  final double? clinicLat;
  final double? clinicLng;
  final int consultationFee;
  final List<ClinicWorkingDay> workingDays;
  final bool agreedToTerms;

  bool get basicInfoComplete =>
      fullName.trim().isNotEmpty &&
      specialty != null &&
      degree.trim().isNotEmpty &&
      experienceYears > 0;

  bool get verificationComplete =>
      documents.any((d) => d.type == DocumentType.medicalLicense) &&
      documents.any((d) => d.type == DocumentType.nationalId);

  bool get clinicScheduleComplete =>
      clinicName.trim().isNotEmpty &&
      clinicAddress.trim().isNotEmpty &&
      city != null &&
      consultationFee > 0 &&
      workingDays.any((d) => d.isEnabled);

  DoctorRegistrationDraft copyWith({
    String? fullName,
    String? specialty,
    String? degree,
    String? email,
    int? experienceYears,
    String? bio,
    String? profilePhotoLocalPath,
    String? profilePhotoDataUri,
    List<UploadedDocument>? documents,
    String? clinicName,
    String? clinicAddress,
    String? city,
    double? clinicLat,
    double? clinicLng,
    int? consultationFee,
    List<ClinicWorkingDay>? workingDays,
    bool? agreedToTerms,
  }) => DoctorRegistrationDraft(
    fullName: fullName ?? this.fullName,
    specialty: specialty ?? this.specialty,
    degree: degree ?? this.degree,
    email: email ?? this.email,
    experienceYears: experienceYears ?? this.experienceYears,
    bio: bio ?? this.bio,
    profilePhotoLocalPath: profilePhotoLocalPath ?? this.profilePhotoLocalPath,
    profilePhotoDataUri: profilePhotoDataUri ?? this.profilePhotoDataUri,
    documents: documents ?? this.documents,
    clinicName: clinicName ?? this.clinicName,
    clinicAddress: clinicAddress ?? this.clinicAddress,
    city: city ?? this.city,
    clinicLat: clinicLat ?? this.clinicLat,
    clinicLng: clinicLng ?? this.clinicLng,
    consultationFee: consultationFee ?? this.consultationFee,
    workingDays: workingDays ?? this.workingDays,
    agreedToTerms: agreedToTerms ?? this.agreedToTerms,
  );
}
