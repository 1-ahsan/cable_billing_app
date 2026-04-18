import 'package:flutter/material.dart';
import 'package:cable_billing_app/Database/db_helper.dart';
import 'package:cable_billing_app/Models/Customer.dart';
import 'package:cable_billing_app/Models/Bill.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  // 1. A key to identify our form and validate it
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers to grab the text from the input boxes
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _addressController = TextEditingController();
  final _feeController = TextEditingController();
  final _numberController = TextEditingController();
  final _codeController = TextEditingController();
  final _fatherController = TextEditingController();

  // A variable to hold the dropdown choice
  String _selectedService = 'Cable';

  // 3. The function that runs when they click "Save"
  void _saveCustomer() async {
    // Check if all required fields are filled out
    if (_formKey.currentState!.validate()) {

      // Create the Customer object using our Model
      Customer newCustomer = Customer(
        name: _nameController.text,
        idCardNumber: _idCardController.text,
        contactInfo: _numberController.text,
        address: _addressController.text,
        serviceType: _selectedService,
        monthlyFee: double.parse(_feeController.text),
        connectionDate: _formattedDate, // updated
        connectionCode: _codeController.text, // update 2
        isActive: 1,
        fatherName: _fatherController.text,
      );

      // Send it to the database!
      int newlyCreatedId = await DatabaseHelper.instance.insertCustomer(newCustomer);

      DateTime now = DateTime.now();
      List<String> monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
      String currentMonth = '${monthNames[now.month - 1]} ${now.year}';

      // 4. Create their very first bill automatically
      Bill initialBill = Bill(
        customerId: newlyCreatedId, // We use the ID SQLite just gave us
        billingMonth: currentMonth,
        amountDue: newCustomer.monthlyFee,
        isPaid: 0, // Unpaid by default
      );

      await DatabaseHelper.instance.insertBill(initialBill);

      // Show a success message at the bottom of the screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer Added Successfully!')),
        );
        // Go back to the previous screen
        Navigator.pop(context);
      }
    }
  }


  // --- NEW VARIABLES FOR DATE PICKER ---
  DateTime _selectedDate = DateTime.now();
  final List<String> _monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  String get _formattedDate {
    return '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  Future<void> _pickConnectionDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Usually can't connect in the future
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Customer'),
        backgroundColor: Colors.blue.shade100,
      ),
      // Padding gives our form some breathing room from the edges
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _fatherController,
                decoration: const InputDecoration(labelText: 'Father Name'),
                validator: (value) => value!.isEmpty ? 'Please enter father name' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _idCardController,
                decoration: const InputDecoration(labelText: 'ID Card Number'),
                validator: (value) => value!.isEmpty ? 'Please enter an ID number' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) => value!.isEmpty ? 'Please enter phone number' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Please enter an address' : null,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: const InputDecoration(labelText: 'Service Type'),
                items: ['Cable', 'Internet', 'Both'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedService = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Connection Code'),
                validator: (value) => value!.isEmpty ? 'Please enter the connection code' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _feeController,
                decoration: const InputDecoration(labelText: 'Monthly Fee (Rs.)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter the fee' : null,
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Connection Date: $_formattedDate',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickConnectionDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Change Date'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveCustomer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Customer', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}