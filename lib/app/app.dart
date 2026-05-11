import 'package:flutter/material.dart';

import 'di/providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  App({AppDependencies? dependencies, super.key})
    : dependencies = dependencies ?? AppDependencies();

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      dependencies: dependencies,
      child: MaterialApp(
        title: 'X Scout Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRouter.initialRoute,
        routes: AppRouter.routes,
      ),
    );
  }
}
