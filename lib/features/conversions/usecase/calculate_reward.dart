import '../data/conversion_functions_repository.dart';

class CalculateReward {
  const CalculateReward(this._repository);

  final ConversionFunctionsRepository _repository;

  Future<num> call({required num salesAmount, num? rewardRate}) {
    return _repository.calculateReward(
      salesAmount: salesAmount,
      rewardRate: rewardRate,
    );
  }
}
