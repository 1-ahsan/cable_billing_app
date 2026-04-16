import 'package:flutter/material.dart';
import 'package:cable_billing_app/Database/db_helper.dart';
import 'package:cable_billing_app/Models/Bill.dart';
import 'package:cable_billing_app/Models/Customer.dart';
import 'package:cable_billing_app/Widgets/bill_card.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  DateTime _selectedDate = DateTime.now();
  final List<String> _monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

  List<Map<String, dynamic>> _allBills = [];
  List<Map<String, dynamic>> _foundBills = [];
  bool _isLoading = false;

  double _totalIncome = 0.0;
  int _unpaidCount = 0;

  // --- NEW: Variables to remember both filters ---
  String _searchQuery = '';
  String _statusFilter = 'All'; // Can be 'All', 'Pending', or 'Paid'

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  String get _formattedMonth {
    return '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  Future<void> _pickMonthAndYear() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select any day in the desired month',
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _loadBills();
    }
  }

  Future<void> _loadBills() async {
    final bills = await DatabaseHelper.instance.getBillsWithCustomerDetails(_formattedMonth);
    final stats = await DatabaseHelper.instance.getMonthlyBillStats(_formattedMonth);
    final income = await DatabaseHelper.instance.getMonthlyIncome(_formattedMonth);

    setState(() {
      _allBills = bills;
      _unpaidCount = stats['unpaid'] ?? 0;
      _totalIncome = income;
    });

    // IMPORTANT: Re-apply the filters every time we load new data!
    _applyFilters();
  }

  // --- NEW: The Double Filter Engine ---
  void _applyFilters() {
    List<Map<String, dynamic>> results = _allBills;

    // 1. First, filter by Status (Paid/Pending)
    if (_statusFilter == 'Paid') {
      results = results.where((bill) => bill['is_paid'] == 1).toList();
    } else if (_statusFilter == 'Pending') {
      results = results.where((bill) => bill['is_paid'] == 0).toList();
    }

    // 2. Second, filter those results by the Search Bar text
    if (_searchQuery.isNotEmpty) {
      results = results.where((bill) {
        final nameMatch = bill['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        final phoneMatch = bill['contact_info']?.toString().contains(_searchQuery) ?? false;
        return nameMatch || phoneMatch;
      }).toList();
    }

    // Update the screen with the final filtered list
    setState(() {
      _foundBills = results;
    });
  }

  Future<void> _generateBills() async {
    setState(() => _isLoading = true);

    final existingBills = await DatabaseHelper.instance.getBillsByMonth(_formattedMonth);
    if (existingBills.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bills for $_formattedMonth already exist!')));
      setState(() => _isLoading = false);
      return;
    }

    List<Customer> allCustomers = await DatabaseHelper.instance.getAllCustomers();
    if (allCustomers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No customers found!')));
      setState(() => _isLoading = false);
      return;
    }

    for (var customer in allCustomers) {
      Bill newBill = Bill(
        customerId: customer.customerId!,
        billingMonth: _formattedMonth,
        amountDue: customer.monthlyFee,
        isPaid: 0,
      );
      await DatabaseHelper.instance.insertBill(newBill);
    }

    await _loadBills();
    setState(() => _isLoading = false);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated bills for $_formattedMonth!')));
  }

  Future<void> _markAsPaid(int billId) async {
    await DatabaseHelper.instance.markBillAsPaid(billId);
    _loadBills();
  }
  Future<void> _markAsUnpaid(int billId) async {
    await DatabaseHelper.instance.markBillAsUnpaid(billId);
    _loadBills(); // Refresh the list to update the Income and Unpaid statistics!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing Management'), backgroundColor: Colors.blue.shade100),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. TOP CONTROLS ---
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month, color: Colors.blue),
                      label: Text(
                        _formattedMonth,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onPressed: _pickMonthAndYear,
                    ),
                    ElevatedButton.icon(
                      icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.receipt),
                      label: const Text('Generate Bills'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                      onPressed: _isLoading ? null : _generateBills,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // --- 2. STATISTICS ---
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade100,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Total Income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 8),
                          Text('Rs. $_totalIncome', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade100,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Pending Bills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          const SizedBox(height: 8),
                          Text('$_unpaidCount Unpaid', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- 3. FILTER AND SEARCH SECTION ---
            Row(
              children: [
                // Text Search Bar
                Expanded(
                  flex: 2,
                  child: TextField(
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFilters(); // Trigger the double filter
                    },
                    decoration: const InputDecoration(
                      labelText: 'Search Name or Phone',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Status Segmented Button (All / Pending / Paid)
                Expanded(
                  flex: 3,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(value: 'All', label: Text('All Bills')),
                      ButtonSegment<String>(value: 'Pending', label: Text('Pending')),
                      ButtonSegment<String>(value: 'Paid', label: Text('Paid')),
                    ],
                    selected: {_statusFilter},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _statusFilter = newSelection.first;
                      });
                      _applyFilters(); // Trigger the double filter
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- 4. BILLS LIST ---
            Expanded(
              child: _foundBills.isEmpty
                  ? const Center(
                  child: Text(
                      'No bills match your filters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey)
                  )
              )
                  : ListView.builder(
                itemCount: _foundBills.length,
                itemBuilder: (context, index) {
                  final bill = _foundBills[index];
                  final isPaid = bill['is_paid'] == 1;

                  return BillCard(
                    bill: bill,
                    onMarkPaid: () => _markAsPaid(bill['bill_id']),
                    onMarkUnpaid: () => _markAsUnpaid(bill['bill_id']), // --- NEW ---
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