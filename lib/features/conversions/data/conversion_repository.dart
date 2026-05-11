import '../model/conversion.dart';

abstract interface class ConversionRepository {
  Stream<List<Conversion>> watchConversions();
}
