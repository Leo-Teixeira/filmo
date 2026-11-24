import 'package:filmo/core/network/retry.dart';
import 'package:filmo/features/household/data/household_repository.dart';
import 'package:filmo/features/household/domain/household_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'household_provider.g.dart';

@Riverpod(retry: retryTransient)
Future<List<HouseholdEntry>?> householdCollections(Ref ref) async {
  final repository = ref.watch(householdRepositoryProvider);
  return await repository.householdCollection();
}
