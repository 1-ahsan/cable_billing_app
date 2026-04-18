import 'package:flutter/material.dart';
import 'package:cable_billing_app/Database/db_helper.dart';
import 'package:cable_billing_app/Models/Customer.dart';
import 'edit_customer_screen.dart'; // We will build this next!
import 'customer_history_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  // We keep two lists. One is the master copy, one is the filtered copy for the UI.
  List<Customer> _allCustomers = [];
  List<Customer> _foundCustomers = [];

  String _currentSort = 'Latest First';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // 1. Fetch data from SQLite
  Future<void> _loadCustomers() async {
    final customers = await DatabaseHelper.instance.getAllCustomers();
    setState(() {
      _allCustomers = customers;
      _foundCustomers = customers; // Initially, show all
    });
    _sortList(_currentSort); // Apply default sorting
  }

  // 2. Real-time Search Logic (Fires on every keystroke)
  void _runFilter(String enteredKeyword) {
    List<Customer> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allCustomers; // If search is empty, show all
    } else {
      results = _allCustomers.where((customer) {
        // We make everything lowercase so 'Ali' matches 'ali'
        final nameMatch = customer.name.toLowerCase().contains(enteredKeyword.toLowerCase());
        final idMatch = customer.idCardNumber.contains(enteredKeyword);
        final phoneMatch = customer.contactInfo?.contains(enteredKeyword) ?? false;
        final codeMatch = customer.connectionCode.contains(enteredKeyword);

        return nameMatch || idMatch || phoneMatch || codeMatch;
      }).toList();
    }

    setState(() {

      _foundCustomers = results;
    });
  }

  // 3. Sorting Logic
  void _sortList(String sortChoice) {
    setState(() {
      _currentSort = sortChoice;
      _foundCustomers = _allCustomers;
      if (sortChoice == 'Name (A-Z)') {
        _foundCustomers.sort((a, b) => a.name.compareTo(b.name));
      } else if (sortChoice == 'Code') {
        _foundCustomers.sort((a, b) => a.connectionCode.compareTo(b.connectionCode));
      } else if (sortChoice == 'Latest First') {
        // Since customerId auto-increments, higher ID means newer
        _foundCustomers.sort((a, b) => b.customerId!.compareTo(a.customerId!));
      } else if(sortChoice == 'Active'){
        final active = _foundCustomers.where((customer){
          return customer.isActive == 1;
        }).toList();
        _foundCustomers = active;
      } else if(sortChoice == 'Inactive'){
        final inactive = _foundCustomers.where((customer){
          return customer.isActive == 0;
        }).toList();
        _foundCustomers = inactive;
      }
    });
  }

  void _deactivateCustomer(int id) async {
    // Standard confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Customer State?'),
        content: const Text('This will change the customer state, but keep their payment history safe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Change', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await DatabaseHelper.instance.deactivateCustomer(id);
      _loadCustomers(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Deactivated.')));
      }
    }
  }


  Color _getCardColor(int status){
    if(status == 0){
      return Colors.grey;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Customers'), backgroundColor: Colors.blue.shade100),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- TOP CONTROL PANEL (Search & Sort) ---
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (value) => _runFilter(value),
                    decoration: const InputDecoration(
                      labelText: 'Search by Name, ID, or Phone',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _currentSort,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: ['Latest First', 'Name (A-Z)', 'Code', 'Active','Inactive']
                        .map((choice) => DropdownMenuItem(value: choice, child: Text(choice)))
                        .toList(),
                    onChanged: (value) => _sortList(value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- THE LIST UI ---
            Expanded(
              child: _foundCustomers.isEmpty
                  ? const Center(child: Text('No customers found', style: TextStyle(fontSize: 18)))
                  : ListView.builder(
                itemCount: _foundCustomers.length,
                itemBuilder: (context, index) {
                  final customer = _foundCustomers[index];

                  // Using a Card makes it look premium and separated
                  return Card(
                    color: _getCardColor(customer.isActive),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade200,
                        child: Text(customer.name[0].toUpperCase()), // First letter of name
                      ),
                      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Phone: ${customer.contactInfo} | Code: ${customer.connectionCode}'
                              '\nCNIC: ${customer.idCardNumber} | Service: ${customer.serviceType} | Connection Date: ${customer.connectionDate}'
                              '\nFee: Rs.${customer.monthlyFee} | Address: ${customer.address}'),
                      isThreeLine: true,

                      // Edit and Delete Buttons
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                            tooltip: 'View Billing History',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerHistoryScreen(customer: customer),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              // Navigate to Edit Screen and wait for it to return
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditCustomerScreen(customer: customer)),
                              );
                              _loadCustomers(); // Refresh list when returning from edit screen
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.archive, color: Colors.red),
                            onPressed: () => _deactivateCustomer(customer.customerId!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}