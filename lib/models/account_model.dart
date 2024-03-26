class AccountDetails {
  late String bankName;
  late int accountNumber;
  late int lastFourDigits;
  late double balance;
  late String uid;

  AccountDetails({
    this.bankName = '',
    this.accountNumber = 0,
    this.lastFourDigits = 0,
    this.balance = 0.0,
    required this.uid,
  });

  factory AccountDetails.fromMap(Map<String, dynamic> map) {
    return AccountDetails(
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? 0,
      lastFourDigits: map['lastFourDigits'] ?? 0,
      balance: (map['balance'] ?? 0.0).toDouble(),
      uid: map['uid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'lastFourDigits': lastFourDigits,
      'balance': balance,
      'uid': uid,
    };
  }
}
