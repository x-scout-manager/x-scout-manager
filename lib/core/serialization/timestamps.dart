class TimestampConverter {
  const TimestampConverter._();

  static DateTime? fromNullable(Object? value) {
    return value is DateTime ? value : null;
  }
}
