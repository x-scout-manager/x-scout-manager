enum Role {
  admin;

  static Role? fromString(String value) {
    return switch (value) {
      'admin' => Role.admin,
      _ => null,
    };
  }
}
