class TransactionDetails {
  late String transactionId;
  late String description;
  late String account;
  late String type;
  late String date;
  late String currency;
  late double amount;
  late String uid;

  TransactionDetails({
    this.transactionId = '',
    this.account = '',
    this.type = '',
    this.description = '',
    this.date = '',
    this.currency = '',
    this.amount = 0.0,
    this.uid = '',
  });

  factory TransactionDetails.fromMap(Map<String, dynamic> map) {
    return TransactionDetails(
      transactionId: map['transactionId'] ?? '',
      account: map['account'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      currency: map['currency'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      uid: map['uid'] ?? '',
    );
  }

  Map<String, dynamic> toJason() {
    return {
      'transaction_id': transactionId,
      'account': account,
      'type': type,
      'description': description,
      'date': date,
      'currency': 'LKR',
      'amount': amount,
      'uid': uid,
    };
  }
}
