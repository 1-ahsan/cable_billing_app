
class Customer {
  final int? customerId; // Nullable because the DB auto-generates this when we first save it
  final String name;
  final String idCardNumber;
  final String? contactInfo; // Nullable in case they don't provide a phone number
  final String address;
  final String serviceType;
  final double monthlyFee;

  // Constructor
  Customer({
    this.customerId,
    required this.name,
    required this.idCardNumber,
    this.contactInfo,
    required this.address,
    required this.serviceType,
    required this.monthlyFee,
  });

  // 1. Translates Dart Object to Database Map (For saving data)
  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'name': name,
      'id_card_number': idCardNumber,
      'contact_info': contactInfo,
      'address': address,
      'service_type': serviceType,
      'monthly_fee': monthlyFee,
    };
  }

  // 2. Translates Database Map to Dart Object (For reading data)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customer_id'],
      name: map['name'],
      idCardNumber: map['id_card_number'],
      contactInfo: map['contact_info'],
      address: map['address'],
      serviceType: map['service_type'],
      monthlyFee: map['monthly_fee'],
    );
  }


  @override
  String toString() {
    return 'Customer(ID: $customerId, Name: $name, CNIC: $idCardNumber, Service: $serviceType, Fee: Rs.$monthlyFee)';
  }




}