class TransactionDetails {
  late String description;
  late String account;
  late String type;
  late String date;
  late double amount;

  TransactionDetails({
    this.account = '',
    this.type = '',
    this.description = '',
    this.date = '',
    this.amount = 0.0,
  });

  factory TransactionDetails.fromMap(Map<String, dynamic> map) {
    return TransactionDetails(
      account: map['account'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJason() {
    return {
      'account': account,
      'type': type,
      'description': description,
      'date': date,
      'amount': amount,
    };
  }
}
