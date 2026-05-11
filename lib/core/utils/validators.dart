class Validators {
  const Validators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '必須項目です';
    }
    return null;
  }
}
