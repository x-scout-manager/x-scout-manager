class ExcludedAccount {
  const ExcludedAccount({
    required this.xUserId,
    required this.username,
    this.reason,
  });

  final String xUserId;
  final String username;
  final String? reason;
}
