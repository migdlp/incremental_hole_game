class Economy {
  Economy({this.balance = 0, this.collected = 0, this.generated = 0});
  int balance, collected, generated;
  void collect(int value) {
    if (value < 0 || collected + value > generated) {
      throw StateError('Ingreso inválido');
    }
    collected += value;
  }

  bool spend(int cost) {
    if (cost < 0 || cost > balance) return false;
    balance -= cost;
    return true;
  }

  void begin() {
    collected = 0;
    generated = 0;
  }

  void bank() {
    balance += collected;
  }
}
