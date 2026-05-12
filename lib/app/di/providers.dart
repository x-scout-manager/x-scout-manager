import 'package:flutter/widgets.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/data/firestore_user_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/usecase/load_session.dart';
import '../../features/auth/usecase/sign_in.dart';
import '../../features/auth/usecase/sign_out.dart';
import '../../features/exclusions/data/exclusion_repository.dart';
import '../../features/exclusions/data/firestore_exclusion_repository.dart';
import '../../features/exclusions/usecase/save_exclusion_keywords.dart';
import '../../features/settings/data/firestore_settings_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/usecase/load_scout_settings.dart';
import '../../features/settings/usecase/save_scout_settings.dart';
import '../../features/settings/usecase/save_tags.dart';
import '../../features/templates/data/firestore_template_repository.dart';
import '../../features/templates/data/template_repository.dart';
import '../../features/templates/usecase/load_templates.dart';
import '../../features/templates/usecase/save_template.dart';

class AppDependencies {
  AppDependencies({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    SettingsRepository? settingsRepository,
    ExclusionRepository? exclusionRepository,
    TemplateRepository? templateRepository,
  }) : authRepository = authRepository ?? FirebaseAuthRepository(),
       userRepository = userRepository ?? FirestoreUserRepository(),
       settingsRepository = settingsRepository ?? FirestoreSettingsRepository(),
       exclusionRepository =
           exclusionRepository ?? FirestoreExclusionRepository(),
       templateRepository = templateRepository ?? FirestoreTemplateRepository();

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final SettingsRepository settingsRepository;
  final ExclusionRepository exclusionRepository;
  final TemplateRepository templateRepository;

  SignIn get signIn => SignIn(authRepository, userRepository);

  LoadSession get loadSession => LoadSession(authRepository, userRepository);

  SignOut get signOut => SignOut(authRepository);

  LoadScoutSettings get loadScoutSettings =>
      LoadScoutSettings(settingsRepository);

  SaveScoutSettings get saveScoutSettings =>
      SaveScoutSettings(settingsRepository);

  SaveTags get saveTags => SaveTags(settingsRepository);

  SaveExclusionKeywords get saveExclusionKeywords =>
      SaveExclusionKeywords(exclusionRepository);

  LoadTemplates get loadTemplates => LoadTemplates(templateRepository);

  SaveTemplate get saveTemplate => SaveTemplate(templateRepository);
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
