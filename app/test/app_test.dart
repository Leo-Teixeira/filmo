import 'package:filmo/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FilmoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Filmo'), findsOneWidget);
  });
}
