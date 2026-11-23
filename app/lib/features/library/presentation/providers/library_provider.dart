import 'package:filmo/features/library/data/library_repository.dart';
import 'package:filmo/features/library/domain/library_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_provider.g.dart';

@Riverpod()
Future<List<LibraryEntry>?> userLibrary(Ref ref, String? status) =>
    ref.watch(libraryRepositoryProvider).userLibrary(status);
