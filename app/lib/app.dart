import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

class FilmoApp extends ConsumerWidget {
  const FilmoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Filmo',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      routerConfig: router,
    );
  }
}
