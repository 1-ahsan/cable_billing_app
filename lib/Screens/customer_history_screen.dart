import 'package:flutter/material.dart';
import 'package:cable_billing_app/Database/db_helper.dart';
import 'package:cable_billing_app/Widgets/bill_card.dart';
import 'package:cable_billing_app/Models/Customer.dart';

class CustomerHistoryScreen extends StatefulWidget {
  final Customer customer;

  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  List<Map<String, dynamic>> _billingHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseHelper.instance.getCustomerBillingHistory(widget.customer.customerId!);
    setState(() {
      _billingHistory = history;
      _isLoading = false;
    });
  }

  Future<void> _markAsPaid(int billId) async {
    await DatabaseHelper.instance.markBillAsPaid(billId);
    _loadHistory(); // Instantly refreshes this screen's list
  }
  Future<void> _markAsUnpaid(int billId) async {
    await DatabaseHelper.instance.markBillAsUnpaid(billId);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('${widget.customer.name}\'s History'),
          backgroundColor: Colors.blue.shade100
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _billingHistory.isEmpty
          ? const Center(child: Text('No billing history found for this customer.', style: TextStyle(fontSize: 16)))
          : ListView.builder(
        padding: const EdgeInsets.only(top: 10),
        itemCount: _billingHistory.length,
        itemBuilder: (context, index) {
          final bill = _billingHistory[index];

          // Using your new custom widget!
          return BillCard(
            bill: bill,
            onMarkPaid: () => _markAsPaid(bill['bill_id']),
            onMarkUnpaid: () => _markAsUnpaid(bill['bill_id']), // --- NEW ---
          );
        },
      ),
    );
  }
}