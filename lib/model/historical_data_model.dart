class HistoricalDataModel {
  final int id;
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final String category;

  final double? change;
  final bool isBankHoliday;
  final String? description;
  final double? volume;
  final double? openInterest;

  HistoricalDataModel({
    required this.id,
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.category,
    this.change,
    this.isBankHoliday = false,
    this.description,
    this.volume,
    this.openInterest,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory HistoricalDataModel.fromJson(Map<String, dynamic> json) {
    final rawDate =
        json['tanggal']?.toString() ?? json['taggal']?.toString() ?? '';

    return HistoricalDataModel(
      id: _parseInt(json['id']),

      date: _parseDate(rawDate),

      open: _parseDouble(json['open']),

      high: _parseDouble(json['high']),

      low: _parseDouble(json['low']),

      close: _parseDouble(json['close']),

      category: json['category']?.toString() ?? '',

      change: _parseNullableDouble(json['chg']),

      isBankHoliday: json['isBankHoliday'] == true,

      description: json['description']?.toString(),

      volume: _parseNullableDouble(json['volume']),

      openInterest: _parseNullableDouble(json['open_interest']),
    );
  }

  // ============================================================
  // PARSE HELPER
  // ============================================================

  static int _parseInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = double.tryParse(value.toString());

    return parsed;
  }

  static DateTime _parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime(2000, 1, 1);
    }
  }

  // ============================================================
  // DATE FORMATTING
  // ============================================================

  String get dateFormatted {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // PRICE FORMATTING
  // ============================================================

  String get openFormatted {
    return _formatNumber(open);
  }

  String get highFormatted {
    return _formatNumber(high);
  }

  String get lowFormatted {
    return _formatNumber(low);
  }

  String get closeFormatted {
    return _formatNumber(close);
  }

  // ============================================================
  // CHANGE FORMATTING
  // ============================================================

  String get changeFormatted {
    if (change == null) {
      return '-';
    }

    final value = change!;

    if (value > 0) {
      return '+${_formatNumber(value)}';
    }

    return _formatNumber(value);
  }

  // ============================================================
  // VOLUME FORMATTING
  // ============================================================

  String get volumeFormatted {
    if (volume == null) {
      return '-';
    }

    return _formatNumber(volume!);
  }

  // ============================================================
  // OPEN INTEREST FORMATTING
  // ============================================================

  String get openInterestFormatted {
    if (openInterest == null) {
      return '-';
    }

    return _formatNumber(openInterest!);
  }

  // ============================================================
  // CATEGORY / MARKET
  // ============================================================

  String get marketName {
    switch (category.toUpperCase()) {
      case 'LGD DAILY':
        return 'Emas';

      case 'HSI DAILY':
        return 'HKK';

      case 'SNI DAILY':
        return 'JPK';

      default:
        return category;
    }
  }

  // ============================================================
  // PRIVATE NUMBER FORMATTER
  // ============================================================

  String _formatNumber(double value) {
    // Kalau angka bulat, tidak perlu .00
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    // Maksimal 2 angka di belakang koma
    return value.toStringAsFixed(2);
  }
}
