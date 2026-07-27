import 'candidate.dart';

class CandidatePageCursor {
  const CandidatePageCursor({
    required this.candidateId,
    required this.status,
    required this.updatedAt,
  });

  final String candidateId;
  final String status;
  final DateTime updatedAt;
}

class CandidatePage {
  const CandidatePage({required this.candidates, required this.nextCursor});

  final List<Candidate> candidates;
  final CandidatePageCursor? nextCursor;

  bool get hasNextPage => nextCursor != null;
}
