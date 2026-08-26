class GoldPriceModel {
  final double pricePerGram;
  final String currency;
  final DateTime updatedAt;

  GoldPriceModel({
    required this.pricePerGram,
    required this.currency,
    required this.updatedAt,
  });

  factory GoldPriceModel.fromJson(Map<String, dynamic> json) {
    // Parsing harga per troy ounce (oz) secara aman
    final rawPrice = json['price'];
    double pricePerOz = 0.0;

    if (rawPrice != null) {
      if (rawPrice is num) {
        pricePerOz = rawPrice.toDouble();
      } else if (rawPrice is String) {
        pricePerOz = double.tryParse(rawPrice) ?? 0.0;
      }
    }

    // 1 troy ounce = 31.1034768 gram
    double gramPrice = pricePerOz / 31.1034768;

    // Parsing timestamp dari API jika tersedia (dalam format unix epoch seconds)
    DateTime parsedDate = DateTime.now();
    if (json['timestamp'] != null && json['timestamp'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as int) * 1000);
    }

    return GoldPriceModel(
      pricePerGram: gramPrice,
      currency: json['currency']?.toString() ?? 'IDR',
      updatedAt: parsedDate,
    );
  }

  @override
  String toString() {
    return 'GoldPriceModel(pricePerGram: $pricePerGram, currency: $currency, updatedAt: $updatedAt)';
  }
}