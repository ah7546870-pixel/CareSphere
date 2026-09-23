import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caresphere/main.dart';
import 'package:caresphere/data/repositories/auth_repository.dart';
import 'package:caresphere/data/repositories/ai_repository.dart';
import 'package:caresphere/data/models/ai_prediction_model.dart';
import 'login_flow_test.dart';

void main() {
  testWidgets('CareSphereApp smoke test', (WidgetTester tester) async {
    final mockRepo = MockAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          aiPredictionProvider.overrideWith((ref) => Stream.value(AiPredictionModel.mock())),
        ],
        child: const CareSphereApp(),
      ),
    );
    expect(find.byType(CareSphereApp), findsOneWidget);

    // Fast-forward through splash timer and onboarding
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
  });
}
