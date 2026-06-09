import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/functions_error_mapper.dart';

abstract interface class ConversionFunctionsRepository {
  Future<String> createConversion({
    required String sendHistoryId,
    required num salesAmount,
    String? evidenceNote,
  });
}

class FirebaseConversionFunctionsRepository
    implements ConversionFunctionsRepository {
  FirebaseConversionFunctionsRepository({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFunctions _functions;

  @override
  Future<String> createConversion({
    required String sendHistoryId,
    required num salesAmount,
    String? evidenceNote,
  }) async {
    try {
      final callable = _functions.httpsCallable('createConversion');
      final payload = <String, dynamic>{
        'sendHistoryId': sendHistoryId,
        'salesAmount': salesAmount,
      };
      if (evidenceNote != null && evidenceNote.trim().isNotEmpty) {
        payload['evidenceNote'] = evidenceNote.trim();
      }
      final result = await callable.call<Map<String, dynamic>>(payload);
      final conversionId = result.data['conversionId'];
      if (conversionId is! String || conversionId.isEmpty) {
        throw const AppError('成果IDを確認できませんでした。');
      }
      return conversionId;
    } on AppError {
      rethrow;
    } catch (error) {
      throw FunctionsErrorMapper.map(error);
    }
  }
}
