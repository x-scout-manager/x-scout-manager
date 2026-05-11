import 'package:flutter/widgets.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/data/firestore_user_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/usecase/load_session.dart';
import '../../features/auth/usecase/sign_in.dart';
import '../../features/auth/usecase/sign_out.dart';

class AppDependencies {
  AppDependencies({
    AuthRepository? authRepository,
    UserRepository? userRepository,
  }) : authRepository = authRepository ?? FirebaseAuthRepository(),
       userRepository = userRepository ?? FirestoreUserRepository();

  final AuthRepository authRepository;
  final UserRepository userRepository;

  SignIn get signIn => SignIn(authRepository, userRepository);

  LoadSession get loadSession => LoadSession(authRepository, userRepository);

  SignOut get signOut => SignOut(authRepository);
}

class AppProviders extends InheritedWidget {
  const AppProviders({
    required this.dependencies,
    required super.child,
    super.key,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppProviders>();
    assert(provider != null, 'AppProviders is not found in the widget tree.');
    return provider!.dependencies;
  }

  static AppDependencies read(BuildContext context) {
    final provider = context
        .getElementForInheritedWidgetOfExactType<AppProviders>()
        ?.widget;
    assert(provider is AppProviders, 'AppProviders is not found in the tree.');
    return (provider! as AppProviders).dependencies;
  }

  @override
  bool updateShouldNotify(AppProviders oldWidget) {
    return dependencies != oldWidget.dependencies;
  }
}
