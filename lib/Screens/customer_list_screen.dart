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

        return nameMatch || idMatch || phoneMatch;
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
      if (sortChoice == 'Name (A-Z)') {
        _foundCustomers.sort((a, b) => a.name.compareTo(b.name));
      } else if (sortChoice == 'Fee (High-Low)') {
        _foundCustomers.sort((a, b) => b.monthlyFee.compareTo(a.monthlyFee));
      } else if (sortChoice == 'Latest First') {
        // Since customerId auto-increments, higher ID means newer
        _foundCustomers.sort((a, b) => b.customerId!.compareTo(a.customerId!));
      }
    });
  }

  // 4. Delete Confirmation Popup
  void _confirmDelete(int customerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Customer?"),
          content: const Text(
            "Are you sure you want to delete this customer? This action cannot be undone and will remove all their data.",
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(), // Close popup
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete permanently", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await DatabaseHelper.instance.deleteCustomer(customerId);
                Navigator.of(context).pop(); // Close popup
                _loadCustomers(); // Refresh the list

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer Deleted')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
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
                    items: ['Latest First', 'Name (A-Z)', 'Fee (High-Low)']
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
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade200,
                        child: Text(customer.name[0].toUpperCase()), // First letter of name
                      ),
                      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Number: ${customer.contactInfo} | Address: ${customer.address}'
                              '\nCNIC: ${customer.idCardNumber} | Service: ${customer.serviceType}'
                              '\nFee: Rs.${customer.monthlyFee}'),
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
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(customer.customerId!),
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