class RouteGuardResult {
  const RouteGuardResult.allow() : redirectPath = null;
  const RouteGuardResult.redirect(this.redirectPath);

  final String? redirectPath;

  bool get isAllowed => redirectPath == null;
}
