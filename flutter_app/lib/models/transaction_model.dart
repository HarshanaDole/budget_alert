class TransactionDetails {
  late String description;
  late int account;
  late String type;
  late String date;
  late String currency;
  late double amount;

  TransactionDetails({
    this.account = 0,
    this.type = '',
    this.description = '',
    this.date = '',
    this.currency = '',
    this.amount = 0.0,
  });

  factory TransactionDetails.fromMap(Map<String, dynamic> map) {
    return TransactionDetails(
      account: map['account'] ?? 0.toInt(),
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      currency: map['currency'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJason() {
    return {
      'account': account,
      'type': type,
      'description': description,
      'date': date,
      'currency': 'LKR',
      'amount': amount,
    };
  }
}
