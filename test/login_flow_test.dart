import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caresphere/data/models/user_model.dart';
import 'package:caresphere/data/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  final Map<String, UserModel> _users = {
    'ah7546870@gmail.com': UserModel.defaultPatient().copyWith(email: 'ah7546870@gmail.com'),
    'aslam.h2025aiml@sece.ac.in': UserModel.defaultPatient().copyWith(email: 'aslam.h2025aiml@sece.ac.in'),
    'jeyaram@gmail.com': UserModel.defaultPatient().copyWith(email: 'jeyaram@gmail.com', name: 'Jeyaram'),
  };

  final Set<String> _registeredEmails = {
    'ah7546870@gmail.com',
    'aslam.h2025aiml@sece.ac.in',
    'jeyaram@gmail.com',
  };

  final Set<String> _registeredPhones = {
    '9486926042',
    '8754814489',
    '1234567891',
  };

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<bool> checkEmailExists(String email) async {
    return _registeredEmails.contains(email.trim().toLowerCase());
  }

  @override
  Future<bool> checkPhoneExists(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final match = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    return _registeredPhones.any((p) => p.contains(match));
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!await checkEmailExists(cleanEmail)) {
      throw Exception('Wrong email ID. The email "$cleanEmail" is not registered. Please check the email ID or create a new account.');
    }
    _currentUser = _users[cleanEmail] ??
        UserModel.defaultPatient().copyWith(
          email: cleanEmail,
        );
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
    final cleanPhone = phone.trim();

    final emailExists = await checkEmailExists(cleanEmail);
    final phoneExists = await checkPhoneExists(cleanPhone);

    if (emailExists && phoneExists) {
      throw Exception('The mail ID and the mobile number are already exist in the database. Please sign in instead.');
    }
    if (emailExists) {
      throw Exception('The mail ID is already exist in the database ($cleanEmail). Please sign in or use a different email ID.');
    }
    if (phoneExists) {
      throw Exception('The mobile number is already exist in the database ($cleanPhone). Please use a different mobile number.');
    }

    final newUser = UserModel(
      id: 'test-id',
      email: cleanEmail,
      name: name,
      role: role,
      age: age,
      phone: cleanPhone,
      bloodGroup: bloodGroup,
    );
    _users[cleanEmail] = newUser;
    _registeredEmails.add(cleanEmail);
    _registeredPhones.add(cleanPhone);
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
  Future<UserModel?> getPatientByElderCode(String code) async {
    for (final u in _users.values) {
      if (u.elderCode == code.trim()) return u;
    }
    if (code.trim() == '654321') return UserModel.defaultPatient();
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
  group('Auth Repository & Flow Tests', () {
    test('Login succeeds for registered email and populates user model', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      await notifier.login('ah7546870@gmail.com', 'password123');

      final authState = container.read(authStateProvider);
      expect(authState.hasValue, true);
      expect(authState.value, isNotNull);
      expect(authState.value!.name, 'Aslam');
      expect(authState.value!.age, 50);
      expect(authState.value!.bloodGroup, 'B+');
      expect(authState.value!.email, 'ah7546870@gmail.com');
    });

    test('Login fails with error when user mistakenly enters unregistered email', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      // Attempt login with mistaken/unregistered email
      await notifier.login('ah7546850@gmail.com', 'password123');

      final authState = container.read(authStateProvider);
      expect(authState.hasError, true);
      expect(authState.error.toString(), contains('Wrong email ID'));
      expect(authState.error.toString(), contains('ah7546850@gmail.com'));
    });

    test('Signup checks database and rejects duplicate email ID', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      await notifier.signup(
        name: 'Duplicate Tester',
        email: 'ah7546870@gmail.com', // existing email
        password: 'password123',
        role: UserRole.patient,
        age: 60,
        phone: '9999988888', // unique phone
      );

      final authState = container.read(authStateProvider);
      expect(authState.hasError, true);
      expect(authState.error.toString(), contains('The mail ID is already exist'));
    });

    test('Signup checks database and rejects duplicate patient mobile number', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      await notifier.signup(
        name: 'Duplicate Phone Tester',
        email: 'unique_user@gmail.com', // unique email
        password: 'password123',
        role: UserRole.patient,
        age: 60,
        phone: '9486926042', // existing phone
      );

      final authState = container.read(authStateProvider);
      expect(authState.hasError, true);
      expect(authState.error.toString(), contains('The mobile number is already exist'));
    });

    test('Signup checks database and rejects when both email and mobile already exist', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      await notifier.signup(
        name: 'Both Duplicate Tester',
        email: 'ah7546870@gmail.com', // existing email
        password: 'password123',
        role: UserRole.patient,
        age: 60,
        phone: '1234567891', // existing phone
      );

      final authState = container.read(authStateProvider);
      expect(authState.hasError, true);
      expect(authState.error.toString(), contains('The mail ID and the mobile number are already exist'));
    });

    test('Signup creates user in database, leaves user unauthenticated until explicit login', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      await notifier.signup(
        name: 'Brand New User',
        email: 'newpatient@example.com',
        password: 'securepassword123',
        role: UserRole.patient,
        age: 68,
        phone: '9876543210',
      );

      // Account created in DB, but authState remains unauthenticated until login
      final authState = container.read(authStateProvider);
      expect(authState.hasValue, true);
      expect(authState.value, isNull);

      // User must explicitly log in
      await notifier.login('newpatient@example.com', 'securepassword123');
      final loggedInState = container.read(authStateProvider);
      expect(loggedInState.value, isNotNull);
      expect(loggedInState.value!.email, 'newpatient@example.com');
      expect(loggedInState.value!.name, 'Brand New User');
    });

    test('Logout clears state to null, then re-login works smoothly', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      await notifier.logout();
      expect(container.read(authStateProvider).value, isNull);

      await notifier.login('aslam.h2025aiml@sece.ac.in', 'mysecret');
      final authState = container.read(authStateProvider);
      expect(authState.value, isNotNull);
      expect(authState.value!.email, 'aslam.h2025aiml@sece.ac.in');
    });
  });
}
