enum AppEnvironment { development, staging, production }

class Env {
  const Env._();

  static const current = AppEnvironment.development;
}
