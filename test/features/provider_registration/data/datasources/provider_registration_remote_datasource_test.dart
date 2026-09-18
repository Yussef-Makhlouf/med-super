import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_registration/data/datasources/remote/provider_registration_remote_datasource.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ProviderRegistrationRemoteDatasource datasource;

  setUp(() {
    dio = _MockDio();
    datasource = ProviderRegistrationRemoteDatasource(dio);
  });

  test(
    'submit posts to the provider registration endpoint with a mapped body',
    () async {
      final draft = DoctorRegistrationDraft(
        fullName: 'Dr. X',
        specialty: 'cardio',
        degree: 'MD',
        experienceYears: 4,
        bio: 'bio',
        documents: const [
          UploadedDocument(
            id: '1',
            fileName: 'license.pdf',
            sizeBytes: 10,
            localPath: '/tmp/license.pdf',
            type: DocumentType.medicalLicense,
          ),
        ],
        clinicName: 'clinic',
        clinicAddress: 'addr',
        city: 'cairo',
        consultationFee: 150,
        workingDays: [
          const ClinicWorkingDay(
            day: Weekday.monday,
            isEnabled: true,
            from: ClinicTime(hour: 9, minute: 0),
            to: ClinicTime(hour: 17, minute: 0),
          ),
          const ClinicWorkingDay(day: Weekday.tuesday, isEnabled: false),
        ],
      );

      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: ApiPaths.providerRegistrationSubmit,
          ),
          statusCode: 200,
          data: {'doctorId': 'doctor-1'},
        ),
      );

      final doctorId = await datasource.submit(draft);
      expect(doctorId, 'doctor-1');

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          captureAny(),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(captured[0], ApiPaths.providerRegistrationSubmit);
      final body = captured[1] as Map<String, dynamic>;
      expect(body['full_name'], 'Dr. X');
      expect(body['specialty'], 'cardio');
      expect(body['degree'], 'MD');
      expect(body['experience_years'], 4);
      expect(body['bio'], 'bio');
      expect(body['clinic_name'], 'clinic');
      expect(body['clinic_address'], 'addr');
      expect(body['city'], 'cairo');
      expect(body['consultation_fee'], 150);
      expect(body['working_days'], [
        {
          'weekday': 1,
          'startTime': '09:00',
          'endTime': '17:00',
          'slotDurationMinutes': 30,
          'bufferMinutes': 0,
        },
      ]);
    },
  );

  test('submit propagates a DioException thrown by dio.post', () async {
    final exception = DioException(
      requestOptions: RequestOptions(path: ApiPaths.providerRegistrationSubmit),
      type: DioExceptionType.connectionError,
    );
    when(
      () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenThrow(exception);

    await expectLater(
      () => datasource.submit(const DoctorRegistrationDraft()),
      throwsA(same(exception)),
    );
  });
}
