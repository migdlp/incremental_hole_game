class DayResult {
  const DayResult({
    required this.day,
    required this.income,
    required this.generated,
    required this.captured,
    required this.previousIncome,
  });
  final int day, income, generated, captured;
  final int? previousIncome;
  int get lost => generated - income;
  Map<String, dynamic> toJson() => {
    'day': day,
    'income': income,
    'generated': generated,
    'captured': captured,
    'previousIncome': previousIncome,
  };
  factory DayResult.fromJson(Map<String, dynamic> json) => DayResult(
    day: json['day'] as int,
    income: json['income'] as int,
    generated: json['generated'] as int,
    captured: json['captured'] as int,
    previousIncome: json['previousIncome'] as int?,
  );
}

class Progress {
  int day = 1;
  int record = 0;
  DayResult? last;
  void finish(DayResult result) {
    last = result;
    if (result.income > record) record = result.income;
    day++;
  }
}
