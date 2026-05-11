import '../data/conversion_functions_repository.dart';
import '../model/conversion.dart';

class CreateConversion {
  const CreateConversion(this._repository);

  final ConversionFunctionsRepository _repository;

  Future<void> call(Conversion conversion) {
    return _repository.createConversion(conversion);
  }
}
