
class Bill {
  final int? billId;
  final int customerId; // This connects the bill to a specific customer
  final String billingMonth;
  final double amountDue;
  final int isPaid; // We use an integer here because SQLite doesn't have true/false (0 = Unpaid, 1 = Paid)

  // Constructor
  Bill({
    this.billId,
    required this.customerId,
    required this.billingMonth,
    required this.amountDue,
    this.isPaid = 0, // Defaults to 0 (Unpaid) when a new bill is created
  });

  // 1. Translates Dart Object to Database Map
  Map<String, dynamic> toMap() {
    return {
      'bill_id': billId,
      'customer_id': customerId,
      'billing_month': billingMonth,
      'amount_due': amountDue,
      'is_paid': isPaid,
    };
  }

  // 2. Translates Database Map to Dart Object
  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      billId: map['bill_id'],
      customerId: map['customer_id'],
      billingMonth: map['billing_month'],
      amountDue: map['amount_due'],
      isPaid: map['is_paid'],
    );
  }

  @override
  String toString(){
    return "Bill(ID: $billId, CustomerID: $customerId, BillingMonth: $billingMonth, DueAmount: $amountDue, isPaid: $isPaid)"; // {isPaid==0?'unpaid':'paid'}
  }
}