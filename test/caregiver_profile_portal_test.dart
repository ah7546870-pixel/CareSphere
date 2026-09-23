import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caresphere/data/models/user_model.dart';
import 'package:caresphere/data/repositories/auth_repository.dart';
import 'package:caresphere/ui/screens/profile/profile_screen.dart';
import 'package:caresphere/ui/screens/caregiver/caregiver_screen.dart';

class MockTestAuthRepo implements AuthRepository {
  UserModel? _currentUser;
  final Map<String, UserModel> _db = {};

  MockTestAuthRepo({UserModel? initialUser}) {
    _currentUser = initialUser;
    final patient = UserModel.defaultPatient().copyWith(elderCode: '654321');
    _db[patient.email.toLowerCase()] = patient;
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<UserModel?> getPatientByElderCode(String code) async {
    if (code.trim() == '654321') {
      return UserModel.defaultPatient().copyWith(name: 'Aslam', elderCode: '654321');
    }
    return null;
  }

  @override
  Future<UserModel?> login(String email, String password) async => _currentUser;

  @override
  Future<UserModel?> loginCaregiver({
    required String email,
    required String password,
    required String patientCode,
  }) async => _currentUser;

  @override
  Future<UserModel?> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required int age,
    required String phone,
    String? linkedElderCode,
    String bloodGroup = 'B+',
    double height = 170.0,
    double weight = 65.0,
    String medicalConditions = '',
    String emergencyContactName = '',
    String emergencyContactPhone = '',
  }) async {
    final isCaregiver = role == UserRole.caregiver;
    final user = UserModel(
      id: 'test-user',
      email: email,
      name: name,
      role: role,
      age: isCaregiver ? 0 : age,
      phone: phone,
      linkedElderCode: linkedElderCode,
      bloodGroup: isCaregiver ? '' : bloodGroup,
      height: isCaregiver ? 0.0 : height,
      weight: isCaregiver ? 0.0 : weight,
      medicalConditions: isCaregiver ? '' : medicalConditions,
      emergencyContactName: isCaregiver ? '' : emergencyContactName,
      emergencyContactPhone: isCaregiver ? '' : emergencyContactPhone,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<bool> checkEmailExists(String email) async => false;

  @override
  Future<bool> checkPhoneExists(String phone) async => false;

  @override
  Future<UserModel?> updateProfile(UserModel updatedUser) async {
    _currentUser = updatedUser;
    return updatedUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  testWidgets('Caregiver profile does NOT display health vitals (age, height, weight, blood group)', (tester) async {
    final caregiverUser = UserModel(
      id: 'caregiver-harish',
      email: 'aslamh2025@gmail.com',
      name: 'Harish',
      role: UserRole.caregiver,
      phone: '9894843898',
      linkedElderCode: '654321',
      bloodGroup: '',
      age: 0,
      height: 0,
      weight: 0,
    );

    final mockRepo = MockTestAuthRepo(initialUser: caregiverUser);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          authStateProvider.overrideWith((ref) => AuthStateNotifier(mockRepo)),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar title is Caregiver Profile, NOT Patient Health Profile
    expect(find.text('Caregiver Profile'), findsOneWidget);
    expect(find.text('Patient Health Profile'), findsNothing);

    // Verify Caregiver Name & Email & Phone are displayed
    expect(find.text('Harish'), findsOneWidget);
    expect(find.text('aslamh2025@gmail.com'), findsAtLeastNWidgets(1));
    expect(find.text('9894843898'), findsAtLeastNWidgets(1));

    // Verify Caregiver Account Information is displayed
    expect(find.text('Caregiver Account Information'), findsOneWidget);
    expect(find.text('Registered Caregiver / Family Member'), findsOneWidget);

    // Verify Monitored Patient card is displayed
    expect(find.textContaining('Code: #654321'), findsOneWidget);

    // Verify health metrics cards are NOT displayed for caregiver
    expect(find.text('Medical Conditions'), findsNothing);
    expect(find.text('Emergency Contact'), findsNothing);
    expect(find.text('65 kg'), findsNothing);
    expect(find.text('170 cm'), findsNothing);
    expect(find.text('Your Unique Elder Code'), findsNothing);
  });

  testWidgets('Caregiver remote portal displays monitored patient, not caregiver personal health info', (tester) async {
    final caregiverUser = UserModel(
      id: 'caregiver-harish',
      email: 'aslamh2025@gmail.com',
      name: 'Harish',
      role: UserRole.caregiver,
      phone: '9894843898',
      linkedElderCode: '654321',
    );

    final mockRepo = MockTestAuthRepo(initialUser: caregiverUser);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          authStateProvider.overrideWith((ref) => AuthStateNotifier(mockRepo)),
        ],
        child: const MaterialApp(
          home: CaregiverScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Caregiver Remote Portal title
    expect(find.text('Caregiver Remote Portal'), findsOneWidget);

    // Verify Harish is displayed in AppBar as caregiver, NOT as the patient
    expect(find.text('Harish'), findsOneWidget);

    // Verify monitored patient card displays the patient information (Aslam, #654321)
    expect(find.textContaining('Aslam'), findsOneWidget);
    expect(find.textContaining('Patient Code: #654321'), findsOneWidget);
    expect(find.textContaining('Monitored Patient'), findsOneWidget);
    expect(find.text('STABLE CONDITION'), findsOneWidget);
  });
}
