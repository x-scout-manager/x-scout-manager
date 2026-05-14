import '../data/conversion_functions_repository.dart';

class CreateConversion {
  const CreateConversion(this._repository);

  final ConversionFunctionsRepository _repository;

  Future<String> call({
    required String sendHistoryId,
    required num salesAmount,
    num? rewardRate,
    String? evidenceNote,
  }) {
    return _repository.createConversion(
      sendHistoryId: sendHistoryId,
      salesAmount: salesAmount,
      rewardRate: rewardRate,
      evidenceNote: evidenceNote,
    );
  }
}
