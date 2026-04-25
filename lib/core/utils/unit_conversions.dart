class UnitConversions {
  static const distanceUnitKey = 'settings_distance_unit';
  static const currencyKey = 'settings_currency';

  static const usdRates = <String, double>{
    'USD': 1,
    'EUR': 0.92,
    'BYN': 3.27,
    'RUB': 92,
  };

  static const currencySymbols = <String, String>{
    'USD': r'$',
    'EUR': '€',
    'BYN': 'Br',
    'RUB': '₽',
  };

  static String normalizeCurrency(String value) {
    return value == 'GBP' ? 'RUB' : value;
  }

  static double kmToPreferred(double kilometers, String unit) {
    return unit == 'mi' ? kilometers * 0.621371 : kilometers;
  }

  static double preferredToKm(double value, String unit) {
    return unit == 'mi' ? value / 0.621371 : value;
  }

  static String formatDistance(double kilometers, String unit) {
    final converted = kmToPreferred(kilometers, unit);
    final decimals = converted >= 10 ? 0 : 1;
    return '${converted.toStringAsFixed(decimals)} ${unit == 'mi' ? 'mi' : 'km'}';
  }

  static double convertUsd(double amountUsd, String currency) {
    final normalized = normalizeCurrency(currency);
    return amountUsd * (usdRates[normalized] ?? 1);
  }

  static String formatCurrency(double amountUsd, String currency) {
    final normalized = normalizeCurrency(currency);
    final converted = convertUsd(amountUsd, normalized);
    final symbol = currencySymbols[normalized] ?? normalized;
    final decimals = normalized == 'USD' || normalized == 'EUR' ? 2 : 0;

    if (normalized == 'BYN') {
      return '${converted.toStringAsFixed(2)} $symbol';
    }

    return '$symbol${converted.toStringAsFixed(decimals)}';
  }

  static String distanceDescription(String unit) {
    return unit == 'mi'
        ? 'Miles · 1 km ≈ 0.62 mi'
        : 'Kilometers · 1 mi ≈ 1.61 km';
  }

  static String currencyDescription(String currency) {
    final normalized = normalizeCurrency(currency);
    final rate = usdRates[normalized] ?? 1;
    final symbol = currencySymbols[normalized] ?? normalized;

    if (normalized == 'USD') {
      return 'USD · base currency';
    }
    if (normalized == 'BYN') {
      return 'BYN · \$1 ≈ ${rate.toStringAsFixed(2)} $symbol';
    }
    return '$normalized · \$1 ≈ $symbol${rate.toStringAsFixed(0)}';
  }
}
