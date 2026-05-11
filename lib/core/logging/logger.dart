class AppLogger {
  const AppLogger._();

  static void debug(String message) {
    assert(() {
      // ignore: avoid_print
      print(message);
      return true;
    }());
  }
}
