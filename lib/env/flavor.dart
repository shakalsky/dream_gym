/// Which environment a binary was built for.
///
/// Fixed by the entrypoint (`lib/main_development.dart`,
/// `lib/main_production.dart`) rather than read from a define, so it cannot be
/// switched by a build argument — the flavour a build claims to be is the one
/// its `main` says it is.
enum Flavor {
  development,
  production;

  /// Parses the `FLAVOR` value carried in an `env/*.json` file.
  ///
  /// Returns null for anything unrecognised, including the empty string a
  /// missing define yields.
  static Flavor? tryParse(String value) {
    for (final flavor in values) {
      if (flavor.name == value) return flavor;
    }
    return null;
  }

  bool get isDevelopment => this == Flavor.development;

  bool get isProduction => this == Flavor.production;
}
