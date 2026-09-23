import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caresphere/data/models/user_model.dart';
import 'package:caresphere/data/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser = UserModel.defaultPatient();

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<UserModel?> login(String email, String password) async {
    _currentUser = UserModel.defaultPatient().copyWith(
      email: email.trim(),
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
    _currentUser = UserModel(
      id: 'test-id',
      email: email,
      name: name,
      role: role,
      age: age,
      phone: phone,
      bloodGroup: bloodGroup,
    );
    return _currentUser;
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
  Future<void> resetPassword(String email) async {}
}

void main() {
  group('Auth and Navigation Flow Tests', () {
    test('Login sets authenticated state and populates user', () async {
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
