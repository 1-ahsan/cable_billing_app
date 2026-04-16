import 'package:flutter/material.dart';
import 'package:cable_billing_app/Database/db_helper.dart';
import 'package:cable_billing_app/Models/Customer.dart';

class EditCustomerScreen extends StatefulWidget {
  // We require the existing customer object to be passed in
  final Customer customer;
  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _idCardController;
  late TextEditingController _addressController;
  late TextEditingController _numberController;
  late TextEditingController _feeController;
  late String _selectedService;

  @override
  void initState() {
    super.initState();
    // Fill the text boxes with the existing data!
    _nameController = TextEditingController(text: widget.customer.name);
    _idCardController = TextEditingController(text: widget.customer.idCardNumber);
    _addressController = TextEditingController(text: widget.customer.address);
    _numberController = TextEditingController(text: widget.customer.contactInfo);
    _feeController = TextEditingController(text: widget.customer.monthlyFee.toString());
    _selectedService = widget.customer.serviceType;
  }

  void _updateCustomer() async {
    if (_formKey.currentState!.validate()) {
      // Create a NEW customer object, but keep the OLD customerId
      Customer updatedCustomer = Customer(
        customerId: widget.customer.customerId, // IMPORTANT: Keep the same ID so SQLite knows what to update!
        name: _nameController.text,
        idCardNumber: _idCardController.text,
        contactInfo: _numberController.text,
        address: _addressController.text,
        serviceType: _selectedService,
        monthlyFee: double.parse(_feeController.text),
      );

      await DatabaseHelper.instance.updateCustomer(updatedCustomer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Updated!')));
        Navigator.pop(context); // Go back to the list screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Customer'), backgroundColor: Colors.blue.shade100),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
              const SizedBox(height: 10),
              TextFormField(controller: _idCardController, decoration: const InputDecoration(labelText: 'ID Card Number')),
              const SizedBox(height: 10),
              TextFormField(controller: _numberController, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 10),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: const InputDecoration(labelText: 'Service Type'),
                items: ['Cable', 'Internet', 'Both'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedService = newValue!),
              ),
              const SizedBox(height: 10),
              TextFormField(controller: _feeController, decoration: const InputDecoration(labelText: 'Monthly Fee (Rs.)')),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _updateCustomer,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('Update Customer', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}