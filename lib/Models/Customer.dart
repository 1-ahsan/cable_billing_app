
class Customer {
  final int? customerId; // Nullable because the DB auto-generates this when we first save it
  final String name;
  final String idCardNumber;
  final String? contactInfo; // Nullable in case they don't provide a phone number
  final String address;
  final String serviceType;
  final double monthlyFee;
  final String connectionDate; // update 1
  final String connectionCode; // update 2
  final int isActive; // update 3 // --- NEW FIELD (1 = Active, 0 = Inactive) ---
  final String fatherName; // update 4

  // Constructor
  Customer({
    this.customerId,
    required this.name,
    required this.idCardNumber,
    this.contactInfo,
    required this.address,
    required this.serviceType,
    required this.monthlyFee,
    required this.connectionDate,
    required this.connectionCode,
    required this.isActive,
    required this.fatherName,
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
      'connection_date': connectionDate,
      'connection_code': connectionCode,
      'is_active': isActive,
      'father_name': fatherName,
    };
  }

  // 2. Translates Database Map to Dart Object (For reading data)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customer_id'],
      name: map['name'] ?? 'Unknown Name',
      idCardNumber: map['id_card_number']?? 'Unknown',
      contactInfo: map['contact_info'],
      address: map['address'] ?? 'Unknown Address',
      serviceType: map['service_type'] ?? 'Cable',
      monthlyFee: map['monthly_fee'] ?? 0.0,
      connectionDate: map['connection_date'] ?? 'Unknown',
      connectionCode: map['connection_code'] ?? 'Unknown',
      isActive: map['is_active'] ?? '1',
      fatherName: map['father_name'] ?? "Unknown",
    );
  }


  @override
  String toString() {
    return 'Customer(ID: $customerId, '
        'Name: $name, '
        'CNIC: $idCardNumber, '
        'Service: $serviceType, '
        'Fee: Rs.$monthlyFee)';
  }




}