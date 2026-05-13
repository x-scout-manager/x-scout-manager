import 'package:cloud_firestore/cloud_firestore.dart';

class TimestampConverter {
  const TimestampConverter._();

  static DateTime? fromNullable(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return value is DateTime ? value : null;
  }
}
