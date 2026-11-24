import 'package:filmo/core/router/app_routes.dart';
import 'package:filmo/features/household/data/household_repository.dart';
import 'package:filmo/features/household/presentation/providers/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdCollectionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Mes collections')),
      body: household.when(
        data: (household) => household != null
            ? ListView.builder(
                itemCount: household!.length,
                itemBuilder: (context, i) {
                  return ListTile(
                    title: Text(household[i].name),
                    subtitle: Text(household[i].inviteCode),
                  );
                },
              )
            : null,
        error: (err, stackTrace) => Center(child: Text('Erreur')),
        loading: () => Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          context.push("${AppRoutes.household}/${AppRoutes.householdCreate}");
        },
      ),
    );
  }
}
