import 'package:flutter/widgets.dart';

import '../../features/auth/view/pages/login_page.dart';
import '../../features/auth/view/widgets/auth_gate.dart';
import '../../features/candidates/view/pages/candidate_list_page.dart';
import '../../features/conversions/view/pages/conversion_list_page.dart';
import '../../features/dashboard/view/pages/dashboard_page.dart';
import '../../features/exclusions/view/pages/excluded_account_page.dart';
import '../../features/exclusions/view/pages/exclusion_keyword_setting_page.dart';
import '../../features/histories/view/pages/send_history_page.dart';
import '../../features/send_queue/view/pages/send_queue_page.dart';
import '../../features/settings/view/pages/system_setting_page.dart';
import '../../features/settings/view/pages/tag_setting_page.dart';
import '../../features/templates/view/pages/template_list_page.dart';
import 'route_paths.dart';

class AppRouter {
  const AppRouter._();

  static const initialRoute = RoutePaths.dashboard;

  static Map<String, WidgetBuilder> get routes => {
    RoutePaths.login: (_) => const LoginPage(),
    RoutePaths.dashboard: (_) => const AuthGate(child: DashboardPage()),
    RoutePaths.candidates: (_) => const AuthGate(child: CandidateListPage()),
    RoutePaths.sendQueue: (_) => const AuthGate(child: SendQueuePage()),
    RoutePaths.sendHistories: (_) => const AuthGate(child: SendHistoryPage()),
    RoutePaths.excludedAccounts: (_) =>
        const AuthGate(child: ExcludedAccountPage()),
    RoutePaths.templates: (_) => const AuthGate(child: TemplateListPage()),
    RoutePaths.conversions: (_) => const AuthGate(child: ConversionListPage()),
    RoutePaths.tagSettings: (_) => const AuthGate(child: TagSettingPage()),
    RoutePaths.exclusionSettings: (_) =>
        const AuthGate(child: ExclusionKeywordSettingPage()),
    RoutePaths.systemSettings: (_) =>
        const AuthGate(child: SystemSettingPage()),
  };
}
