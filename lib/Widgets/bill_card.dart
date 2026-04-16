import 'package:flutter/material.dart';

class BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final VoidCallback onMarkPaid;
  final VoidCallback onMarkUnpaid; // --- NEW: Added the Undo action ---

  const BillCard({
    super.key,
    required this.bill,
    required this.onMarkPaid,
    required this.onMarkUnpaid, // --- NEW ---
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = bill['is_paid'] == 1;

    return Card(
      color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(
            isPaid ? Icons.check_circle : Icons.warning,
            color: isPaid ? Colors.green : Colors.red,
            size: 40
        ),
        title: Text(
            '${bill['billing_month']} - Rs.${bill['amount_due']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        subtitle: Text(
          'Customer: ${bill['name']} (ID: ${bill['customer_id']})\nPhone: ${bill['contact_info'] ?? 'N/A'}\nAddress: ${bill['address']}',
          style: const TextStyle(height: 1.5),
        ),
        isThreeLine: true,

        // --- UPDATED LOGIC HERE ---
        trailing: isPaid
        // If Paid: Show an outline button to Undo
            ? OutlinedButton.icon(
          icon: const Icon(Icons.undo, size: 18),
          label: const Text('Undo Paid'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          onPressed: onMarkUnpaid, // Triggers our new Undo function
        )
        // If Unpaid: Show the solid green Mark Paid button
            : ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: onMarkPaid,
          child: const Text('Mark Paid'),
        ),
      ),
    );
  }
}