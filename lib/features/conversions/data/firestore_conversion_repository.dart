import 'conversion_repository.dart';
import '../model/conversion.dart';

class FirestoreConversionRepository implements ConversionRepository {
  const FirestoreConversionRepository();

  @override
  Stream<List<Conversion>> watchConversions() {
    return const Stream.empty();
  }
}
