import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caresphere/data/models/user_model.dart';
import 'package:caresphere/data/models/ai_prediction_model.dart';
import 'package:caresphere/data/repositories/auth_repository.dart';
import 'package:caresphere/data/repositories/ai_repository.dart';
import 'package:caresphere/core/routes/app_router.dart';
import 'package:caresphere/ui/screens/auth/role_selection_screen.dart';
import 'package:caresphere/ui/screens/auth/signup_screen.dart';
import 'package:caresphere/ui/screens/auth/login_screen.dart';
import 'package:caresphere/ui/screens/dashboard/elder_dashboard_screen.dart';

class MockRoleSelectionAuthRepo implements AuthRepository {
  UserModel? _currentUser;
  final Map<String, UserModel> _db = {};
  final Map<String, String> _passwords = {};

  MockRoleSelectionAuthRepo() {
    final aslam = UserModel.defaultPatient();
    _db[aslam.email.toLowerCase()] = aslam;
    _passwords[aslam.email.toLowerCase()] = 'password123';
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<UserModel?> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!_db.containsKey(cleanEmail)) {
      throw Exception('Wrong email id. No account found for this email.');
    }
    if (_passwords[cleanEmail] != password) {
      throw Exception('Invalid password.');
    }
    _currentUser = _db[cleanEmail];
    return _currentUser;
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
    if (_db.containsKey(cleanEmail)) {
      throw Exception('The email id is already registered. Please sign in or use another email.');
    }
    for (final u in _db.values) {
      if (u.phone == phone.trim()) {
        throw Exception('The mobile number is already registered. Please sign in or use another number.');
      }
    }

    final newUser = UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: cleanEmail,
      role: role,
      age: age,
      phone: phone,
      elderCode: role == UserRole.patient ? '654321' : null,
      bloodGroup: bloodGroup,
    );

    _db[cleanEmail] = newUser;
    _passwords[cleanEmail] = password;
    // Per user requirement: newly created user stays unauthenticated until explicit login
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
  Future<bool> checkEmailExists(String email) async {
    return _db.containsKey(email.trim().toLowerCase());
  }

  @override
  Future<bool> checkPhoneExists(String phone) async {
    return _db.values.any((u) => u.phone == phone.trim());
  }

  @override
  Future<UserModel?> getPatientByElderCode(String code) async {
    for (final u in _db.values) {
      if (u.elderCode == code.trim()) return u;
    }
    return null;
  }

  @override
  Future<UserModel?> loginCaregiver({
    required String email,
    required String password,
    required String patientCode,
  }) async {
    return login(email, password);
  }

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  testWidgets('Initial open lands on Role Selection, allows signup, requires login before dashboard', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockRoleSelectionAuthRepo();

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
    // Advance past splash screen delay
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // 1. MUST NOT BE ON ELDER DASHBOARD (No auto-login to Aslam)
    expect(find.byType(ElderDashboardScreen), findsNothing);

    // 2. MUST BE ON ROLE SELECTION SCREEN
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.text('Choose Your Role'), findsOneWidget);
    expect(find.text('Patient / Elder'), findsOneWidget);
    expect(find.text('Caregiver / Family Member'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // 3. Tap Patient / Elder card then Continue to Sign Up
    await tester.tap(find.text('Patient / Elder'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue to Sign Up'));
    await tester.pumpAndSettle();

    // 4. MUST BE ON SIGNUP SCREEN with Patient pre-selected
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(find.text('Elder Profile'), findsOneWidget);

    // 5. Fill patient registration details
    await tester.enterText(find.widgetWithText(DarkTextField, 'Full Name'), 'Grandpa Robert');
    await tester.enterText(find.widgetWithText(DarkTextField, 'Age'), '72');
    await tester.enterText(find.widgetWithText(DarkTextField, 'Phone'), '9876543210');

    final emailField = find.widgetWithText(DarkTextField, 'Email Address');
    await tester.ensureVisible(emailField);
    await tester.pumpAndSettle();
    await tester.enterText(emailField, 'robert@caresphere.com');

    final passField = find.widgetWithText(DarkTextField, 'Password');
    await tester.ensureVisible(passField);
    await tester.pumpAndSettle();
    await tester.enterText(passField, 'RobertPass123!');
    await tester.pump();

    // Scroll to and submit Sign Up
    final createBtn = find.text('Create Patient Account');
    await tester.ensureVisible(createBtn);
    await tester.pumpAndSettle();
    await tester.tap(createBtn);
    await tester.pump();
    await tester.pumpAndSettle();

    // 6. Confirms account created & displays Elder Code dialog with 'Proceed to Sign In'
    expect(find.text('Account Created!'), findsOneWidget);
    expect(find.text('Your Unique Elder Code'), findsOneWidget);
    expect(find.text('654321'), findsOneWidget);
    expect(find.text('Proceed to Sign In'), findsOneWidget);

    // 7. Click 'Proceed to Sign In' -> routes to LoginScreen
    await tester.tap(find.text('Proceed to Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(ElderDashboardScreen), findsNothing);

    // 8. Now explicitly login with the newly created account
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'robert@caresphere.com');
    await tester.enterText(loginFields.at(1), 'RobertPass123!');
    await tester.pump();

    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pumpAndSettle();

    // 9. Successfully in ElderDashboardScreen with Grandpa!
    expect(find.byType(ElderDashboardScreen), findsOneWidget);
    expect(find.text('Grandpa'), findsOneWidget);

    // Elapse any remaining simulation timers
    await tester.pump(const Duration(seconds: 5));
  });
}
