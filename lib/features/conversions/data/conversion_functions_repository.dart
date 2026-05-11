import '../model/conversion.dart';

abstract interface class ConversionFunctionsRepository {
  Future<void> createConversion(Conversion conversion);
  Future<num> calculateReward({
    required num salesAmount,
    required num rewardRate,
  });
}

class FirebaseConversionFunctionsRepository
    implements ConversionFunctionsRepository {
  const FirebaseConversionFunctionsRepository();

  @override
  Future<num> calculateReward({
    required num salesAmount,
    required num rewardRate,
  }) async {
    return salesAmount * rewardRate;
  }

  @override
  Future<void> createConversion(Conversion conversion) async {}
}
