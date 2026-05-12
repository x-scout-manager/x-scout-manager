enum CandidateStatus {
  candidate,
  excluded,
  sent,
  sending,
  failed;

  static CandidateStatus fromString(String value) {
    return CandidateStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => CandidateStatus.candidate,
    );
  }

  String get label {
    return switch (this) {
      CandidateStatus.candidate => '候補',
      CandidateStatus.excluded => '除外',
      CandidateStatus.sent => '送信済み',
      CandidateStatus.sending => '送信中',
      CandidateStatus.failed => '失敗',
    };
  }
}
