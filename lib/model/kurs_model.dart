const List<String> kKursBases = ['USD', 'EUR', 'SGD', 'JPY', 'HKD'];

enum KursRange { day, week, month }

class KursPoint {
  final DateTime time;
  final double rate;

  const KursPoint({required this.time, required this.rate});
}

class KursSeries {
  final String base;
  final String quote;
  final List<KursPoint> points;
  final double current;
  final bool isLive;
  final String source;

  const KursSeries({
    required this.base,
    required this.quote,
    required this.points,
    required this.current,
    required this.isLive,
    required this.source,
  });

  double get change => current - points.first.rate;

  double get changePercent {
    final baseRate = points.first.rate;
    if (baseRate == 0) return 0;
    return (change / baseRate) * 100;
  }

  double get low => points.map((p) => p.rate).reduce((a, b) => a < b ? a : b);

  double get high => points.map((p) => p.rate).reduce((a, b) => a > b ? a : b);
}