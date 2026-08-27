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
    return GoldPriceModel(
      date: DateTime.parse(json['date'].toString()),
      open: double.parse(json['open'].toString()),
      high: double.parse(json['high'].toString()),
      low: double.parse(json['low'].toString()),
      close: double.parse(json['close'].toString()),
      changePercentage: changePercentage,
    );
  }
}