class AccountDetails {
  late String bankName;
  late String accountNumber;
  late String account;
  late String lastFourDigits;
  late String cardNumber;
  late double balance;
  late String uid;

  AccountDetails({
    this.bankName = '',
    this.accountNumber = '',
    this.account = '',
    this.lastFourDigits = '',
    this.cardNumber = '',
    this.balance = 0.0,
    required this.uid,
  });

  factory AccountDetails.fromMap(Map<String, dynamic> map) {
    return AccountDetails(
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      account: map['account'] ?? '',
      lastFourDigits: map['lastFourDigits'] ?? '',
      cardNumber: map['cardNumber'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      uid: map['uid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'account': account,
      'lastFourDigits': lastFourDigits,
      'cardNumber': cardNumber,
      'balance': balance,
      'uid': uid,
    };
  }
}
