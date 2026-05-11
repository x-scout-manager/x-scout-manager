import '../data/conversion_repository.dart';
import '../model/conversion.dart';

class LoadConversions {
  const LoadConversions(this._repository);

  final ConversionRepository _repository;

  Stream<List<Conversion>> call() => _repository.watchConversions();
}
