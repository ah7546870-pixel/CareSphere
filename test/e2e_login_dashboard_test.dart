import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caresphere/core/routes/app_router.dart';
import 'package:caresphere/data/models/user_model.dart';
import 'package:caresphere/data/models/ai_prediction_model.dart';
import 'package:caresphere/data/repositories/auth_repository.dart';
import 'package:caresphere/data/repositories/ai_repository.dart';
import 'package:caresphere/ui/screens/dashboard/elder_dashboard_screen.dart';
import 'package:caresphere/ui/screens/auth/login_screen.dart';

class TestAuthRepository implements AuthRepository {
  UserModel? _user;

  TestAuthRepository([this._user]);

  @override
  Future<UserModel?> getCurrentUser() async => _user;

  @override
  Future<UserModel?> login(String email, String password) async {
    _user = UserModel.defaultPatient().copyWith(
      email: email.trim(),
    );
    return _user;
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
    _user = UserModel(
      id: 'signup-id',
      email: email,
      name: name,
      role: role,
      age: age,
      phone: phone,
      bloodGroup: bloodGroup,
    );
    return _user;
  }

  @override
  Future<void> logout() async {
    _user = null;
  }

  @override
  Future<UserModel?> updateProfile(UserModel updatedUser) async {
    _user = updatedUser;
    return _user;
  }

  @override
  Future<bool> checkEmailExists(String email) async => true;

  @override
  Future<bool> checkPhoneExists(String phone) async => false;

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  testWidgets('Complete login to dashboard flow verification', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Start with logged out user
    final testRepo = TestAuthRepository(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(testRepo),
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

    // Initial splash frame
    await tester.pump();

    // Fast-forward past splash (2800ms)
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // Verify we arrived on RoleSelectionScreen
    expect(find.text('Choose Your Role'), findsOneWidget);
    expect(find.text('Patient / Elder'), findsOneWidget);
    expect(find.text('Caregiver / Family Member'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Tap Sign In to go to LoginScreen
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify LoginScreen is shown
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Enter email and password into TextFields
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'ah7546870@gmail.com');
    await tester.enterText(textFields.at(1), 'password123');
    await tester.pump();

    // Tap Sign In button
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify navigation successfully landed on ElderDashboardScreen
    expect(find.byType(ElderDashboardScreen), findsOneWidget);
    expect(find.text('Aslam'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Vitals'), findsWidgets);
    expect(find.text('IoT Hub'), findsWidgets);

    // Verify we did NOT bounce back to LoginScreen
    expect(find.byType(LoginScreen), findsNothing);

    // Elapse any remaining background simulation timers
    await tester.pump(const Duration(seconds: 5));
  });
}
