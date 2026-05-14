import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversion_repository.dart';
import '../model/conversion.dart';

class FirestoreConversionRepository implements ConversionRepository {
  FirestoreConversionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Conversion>> watchConversions() {
    return _firestore
        .collection('conversions')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Conversion.fromJson(doc.id, doc.data()))
              .toList();
        });
  }
}
