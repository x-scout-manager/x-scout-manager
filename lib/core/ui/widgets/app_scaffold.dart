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
      body: body,
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('X Scout Manager'),
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
            _NavigationItem(
              label: '成果証跡',
              icon: Icons.verified_outlined,
              route: RoutePaths.conversions,
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
