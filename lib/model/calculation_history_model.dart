class CalculationHistoryModel {
  final String type;
  final DateTime createdAt;

  final double high;
  final double low;
  final double close;

  final double pp;
  final double r1;
  final double r2;
  final double r3;
  final double r4;
  final double s1;
  final double s2;
  final double s3;
  final double s4;

  CalculationHistoryModel({
    required this.type,
    required this.createdAt,
    required this.high,
    required this.low,
    required this.close,
    required this.pp,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.r4,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
  });
}
