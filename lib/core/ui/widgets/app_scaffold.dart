import 'package:flutter/material.dart';

import '../../../app/router/route_paths.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: _AppNavigationDrawer(currentRoute: currentRoute),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBFCFF), Color(0xFFF4F0FF), Color(0xFFEEF8FF)],
          ),
        ),
        child: body,
      ),
    );
  }
}

class _AppNavigationDrawer extends StatelessWidget {
  const _AppNavigationDrawer({required this.currentRoute});

  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2B2F7D),
                      Color(0xFF5B5FEF),
                      Color(0xFF25C2E5),
                    ],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'X Scout Manager',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Creator Scout Operations',
                      style: TextStyle(color: Color(0xFFDDE8FF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            _NavigationItem(
              label: 'ダッシュボード',
              icon: Icons.dashboard_outlined,
              route: RoutePaths.dashboard,
              currentRoute: currentRoute,
            ),
            _NavigationItem(
              label: '候補一覧',
              icon: Icons.people_alt_outlined,
              route: RoutePaths.candidates,
              currentRoute: currentRoute,
            ),
            _NavigationItem(
              label: '送信キュー',
              icon: Icons.queue_outlined,
              route: RoutePaths.sendQueue,
              currentRoute: currentRoute,
            ),
            _NavigationItem(
              label: '送信履歴',
              icon: Icons.history_outlined,
              route: RoutePaths.sendHistories,
              currentRoute: currentRoute,
            ),
            _NavigationItem(
              label: '除外アカウント',
              icon: Icons.block_outlined,
              route: RoutePaths.excludedAccounts,
              currentRoute: currentRoute,
            ),
            _NavigationItem(
              label: 'テンプレート',
              icon: Icons.article_outlined,
              route: RoutePaths.templates,
              currentRoute: currentRoute,
            ),
            const Divider(),
            _NavigationItem(
              label: 'タグ設定',
              icon: Icons.tag_outlined,
              route: RoutePaths.tagSettings,
              currentRoute: currentRoute,
            ),
            _NavigationItem(
              label: '除外キーワード設定',
              icon: Icons.filter_alt_off_outlined,
              route: RoutePaths.exclusionSettings,
              currentRoute: currentRoute,
            ),
            _NavigationItem(
              label: 'システム設定',
              icon: Icons.settings_outlined,
              route: RoutePaths.systemSettings,
              currentRoute: currentRoute,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.currentRoute,
  });

  final String label;
  final IconData icon;
  final String route;
  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    final selected = currentRoute == route;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: selected
          ? () => Navigator.of(context).pop()
          : () => Navigator.of(context).pushReplacementNamed(route),
    );
  }
}
