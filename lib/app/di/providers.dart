import 'package:flutter/widgets.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/data/firestore_user_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/usecase/load_session.dart';
import '../../features/auth/usecase/sign_in.dart';
import '../../features/auth/usecase/sign_out.dart';
import '../../features/candidates/data/candidate_repository.dart';
import '../../features/candidates/data/candidate_functions_repository.dart';
import '../../features/candidates/data/firestore_candidate_repository.dart';
import '../../features/candidates/usecase/exclude_candidate.dart';
import '../../features/candidates/usecase/load_candidates.dart';
import '../../features/candidates/usecase/restore_candidate.dart';
import '../../features/exclusions/data/exclusion_repository.dart';
import '../../features/exclusions/data/firestore_exclusion_repository.dart';
import '../../features/exclusions/usecase/load_excluded_accounts.dart';
import '../../features/exclusions/usecase/save_exclusion_keywords.dart';
import '../../features/histories/data/firestore_send_history_repository.dart';
import '../../features/histories/data/send_history_repository.dart';
import '../../features/histories/usecase/load_send_histories.dart';
import '../../features/settings/data/firestore_settings_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/usecase/load_scout_settings.dart';
import '../../features/settings/usecase/save_scout_settings.dart';
import '../../features/settings/usecase/save_tags.dart';
import '../../features/send_queue/data/send_queue_functions_repository.dart';
import '../../features/send_queue/data/firestore_send_queue_repository.dart';
import '../../features/send_queue/data/send_queue_repository.dart';
import '../../features/send_queue/usecase/create_send_queue.dart';
import '../../features/send_queue/usecase/load_send_queue.dart';
import '../../features/send_queue/usecase/load_send_queue_items.dart';
import '../../features/send_queue/usecase/load_send_queues.dart';
import '../../features/send_queue/usecase/mark_as_manually_sent.dart';
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
    CandidateRepository? candidateRepository,
    CandidateFunctionsRepository? candidateFunctionsRepository,
    SendHistoryRepository? sendHistoryRepository,
    SendQueueRepository? sendQueueRepository,
    SendQueueFunctionsRepository? sendQueueFunctionsRepository,
  }) : authRepository = authRepository ?? FirebaseAuthRepository(),
       userRepository = userRepository ?? FirestoreUserRepository(),
       settingsRepository = settingsRepository ?? FirestoreSettingsRepository(),
       exclusionRepository =
           exclusionRepository ?? FirestoreExclusionRepository(),
       templateRepository = templateRepository ?? FirestoreTemplateRepository(),
       candidateRepository =
           candidateRepository ?? FirestoreCandidateRepository(),
       candidateFunctionsRepository =
           candidateFunctionsRepository ??
           FirebaseCandidateFunctionsRepository(),
       sendHistoryRepository =
           sendHistoryRepository ?? FirestoreSendHistoryRepository(),
       sendQueueRepository =
           sendQueueRepository ?? FirestoreSendQueueRepository(),
       sendQueueFunctionsRepository =
           sendQueueFunctionsRepository ??
           FirebaseSendQueueFunctionsRepository();

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final SettingsRepository settingsRepository;
  final ExclusionRepository exclusionRepository;
  final TemplateRepository templateRepository;
  final CandidateRepository candidateRepository;
  final CandidateFunctionsRepository candidateFunctionsRepository;
  final SendHistoryRepository sendHistoryRepository;
  final SendQueueRepository sendQueueRepository;
  final SendQueueFunctionsRepository sendQueueFunctionsRepository;

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

  LoadExcludedAccounts get loadExcludedAccounts =>
      LoadExcludedAccounts(exclusionRepository);

  LoadTemplates get loadTemplates => LoadTemplates(templateRepository);

  SaveTemplate get saveTemplate => SaveTemplate(templateRepository);

  LoadCandidates get loadCandidates => LoadCandidates(candidateRepository);

  ExcludeCandidate get excludeCandidate =>
      ExcludeCandidate(candidateFunctionsRepository);

  RestoreCandidate get restoreCandidate =>
      RestoreCandidate(candidateFunctionsRepository);

  LoadSendHistories get loadSendHistories =>
      LoadSendHistories(sendHistoryRepository);

  CreateSendQueue get createSendQueue =>
      CreateSendQueue(sendQueueFunctionsRepository);

  LoadSendQueue get loadSendQueue => LoadSendQueue(sendQueueRepository);

  LoadSendQueues get loadSendQueues => LoadSendQueues(sendQueueRepository);

  LoadSendQueueItems get loadSendQueueItems =>
      LoadSendQueueItems(sendQueueRepository);

  MarkAsManuallySent get markAsManuallySent =>
      MarkAsManuallySent(sendQueueFunctionsRepository);
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
