class GoldPriceModel {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double changePercentage;

  GoldPriceModel({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.changePercentage,
  });

  double get lastPrice => close;

  factory GoldPriceModel.fromJson(
    Map<String, dynamic> json, {
    double changePercentage = 0,
  }) {
    // 1. Ambil tanggal dari key 'tanggal' atau fallback ke 'date'
    final String rawDate = json['tanggal']?.toString() ?? json['date']?.toString() ?? '';

    // 2. Ambil persentase perubahan dari key 'chg' atau fallback ke parameter
    final double rawChg = double.tryParse(json['chg']?.toString() ?? '') ?? changePercentage;

    return GoldPriceModel(
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      open: double.tryParse(json['open']?.toString() ?? '0') ?? 0.0,
      high: double.tryParse(json['high']?.toString() ?? '0') ?? 0.0,
      low: double.tryParse(json['low']?.toString() ?? '0') ?? 0.0,
      close: double.tryParse(json['close']?.toString() ?? '0') ?? 0.0,
      changePercentage: rawChg,
    );
  }

  factory GoldPriceModel.fromMap(
    Map<String, dynamic> map, {
    double changePercentage = 0,
  }) {
    return GoldPriceModel.fromJson(map, changePercentage: changePercentage);
  }

  String get formattedDate =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
}