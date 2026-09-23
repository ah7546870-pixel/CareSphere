import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caresphere/data/models/user_model.dart';
import 'package:caresphere/data/models/ai_prediction_model.dart';
import 'package:caresphere/data/repositories/auth_repository.dart';
import 'package:caresphere/data/repositories/ai_repository.dart';
import 'package:caresphere/core/routes/app_router.dart';
import 'package:caresphere/ui/screens/auth/role_selection_screen.dart';
import 'package:caresphere/ui/screens/auth/login_screen.dart';
import 'package:caresphere/ui/screens/auth/caregiver_login_screen.dart';
import 'package:caresphere/ui/screens/dashboard/caregiver_dashboard_screen.dart';

class MockCaregiverAuthRepo implements AuthRepository {
  UserModel? _currentUser;
  final Map<String, UserModel> _db = {};
  final Map<String, String> _passwords = {};

  MockCaregiverAuthRepo() {
    // Registered patient (Aslam, code: 654321)
    final patient = UserModel.defaultPatient().copyWith(elderCode: '654321');
    _db[patient.email.toLowerCase()] = patient;
    _passwords[patient.email.toLowerCase()] = 'patient123';

    // Registered caregiver
    final caregiver = UserModel(
      id: 'cg-1',
      email: 'nurse.sarah@caresphere.com',
      name: 'Sarah Jenkins',
      role: UserRole.caregiver,
      age: 34,
      phone: '9876543211',
    );
    _db[caregiver.email.toLowerCase()] = caregiver;
    _passwords[caregiver.email.toLowerCase()] = 'caregiver123';
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<UserModel?> getPatientByElderCode(String code) async {
    final cleanCode = code.trim();
    for (final u in _db.values) {
      if (u.elderCode == cleanCode) return u;
    }
    if (cleanCode == '654321') return UserModel.defaultPatient();
    return null;
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!_db.containsKey(cleanEmail)) {
      throw Exception('Wrong email ID. No account found for this email.');
    }
    if (_passwords[cleanEmail] != password) {
      throw Exception('Incorrect password.');
    }
    _currentUser = _db[cleanEmail];
    return _currentUser;
  }

  @override
  Future<UserModel?> loginCaregiver({
    required String email,
    required String password,
    required String patientCode,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanCode = patientCode.trim();

    final patient = await getPatientByElderCode(cleanCode);
    if (patient == null) {
      throw Exception('No patient found with code "$cleanCode". Please verify the 6-digit patient code.');
    }

    final user = await login(cleanEmail, password);
    if (user == null) {
      throw Exception('Incorrect caregiver credentials.');
    }

    final updated = user.copyWith(
      role: UserRole.caregiver,
      linkedElderCode: cleanCode,
    );
    _db[cleanEmail] = updated;
    _currentUser = updated;
    return updated;
  }

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
    final cleanEmail = email.trim().toLowerCase();
    final newUser = UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: cleanEmail,
      role: role,
      age: age,
      phone: phone,
      elderCode: role == UserRole.patient ? '112233' : null,
      linkedElderCode: linkedElderCode,
    );
    _db[cleanEmail] = newUser;
    _passwords[cleanEmail] = password;
    _currentUser = null;
    return newUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserModel?> updateProfile(UserModel updatedUser) async {
    _currentUser = updatedUser;
    return _currentUser;
  }

  @override
  Future<bool> checkEmailExists(String email) async => _db.containsKey(email.trim().toLowerCase());

  @override
  Future<bool> checkPhoneExists(String phone) async => _db.values.any((u) => u.phone == phone.trim());

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  testWidgets('Caregiver login flow: role selection -> caregiver login with patient code -> caregiver dashboard with patient data', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockCaregiverAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          aiPredictionProvider.overrideWith((ref) => Stream.value(AiPredictionModel.mock())),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // 1. We are on Role Selection Screen
    expect(find.byType(RoleSelectionScreen), findsOneWidget);

    // 2. Select Caregiver / Family Member
    await tester.tap(find.text('Caregiver / Family Member'));
    await tester.pumpAndSettle();

    // 3. Tap 'Sign In as Caregiver'
    final caregiverSignInBtn = find.text('Sign In as Caregiver');
    expect(caregiverSignInBtn, findsOneWidget);
    await tester.tap(caregiverSignInBtn);
    await tester.pumpAndSettle();

    // 4. Arrived on CaregiverLoginScreen
    expect(find.byType(CaregiverLoginScreen), findsOneWidget);
    expect(find.text('Caregiver Sign In'), findsOneWidget);
    expect(find.text('Caregiver Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Patient Code Number (6-digit)'), findsOneWidget);

    // 5. Try entering an invalid patient code
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(3));

    await tester.enterText(textFields.at(0), 'nurse.sarah@caresphere.com');
    await tester.enterText(textFields.at(1), 'caregiver123');
    await tester.enterText(textFields.at(2), '999999'); // Invalid code
    await tester.pump();

    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pumpAndSettle();

    // 6. Should display error about invalid patient code
    expect(find.textContaining('No patient found with code "999999"'), findsWidgets);
    expect(find.byType(CaregiverDashboardScreen), findsNothing);

    // 7. Now enter valid patient code '654321' (Aslam's code)
    await tester.enterText(textFields.at(2), '654321');
    await tester.pump();

    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pumpAndSettle();

    // 8. Navigation succeeds and lands on CaregiverDashboardScreen!
    expect(find.byType(CaregiverDashboardScreen), findsOneWidget);
    expect(find.textContaining('Sarah'), findsOneWidget);

    // 9. Displays the linked patient data based on patient code
    expect(find.text('Aslam'), findsOneWidget);
    expect(find.textContaining('#654321'), findsOneWidget);
    expect(find.text('Heart Rate'), findsWidgets);
    expect(find.text('Blood Oxygen'), findsWidgets);

    // Flush timers
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Cross-linking between Patient Login and Caregiver Login works smoothly', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockCaregiverAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // From Role Selection, tap 'Sign In as Patient'
    await tester.tap(find.text('Sign In as Patient'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    // Tap switch to Caregiver
    await tester.tap(find.text('Sign In with Patient Code'));
    await tester.pumpAndSettle();

    expect(find.byType(CaregiverLoginScreen), findsOneWidget);

    // Tap switch back to Patient
    await tester.tap(find.text('Sign In here'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
