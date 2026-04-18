import 'package:flutter/material.dart';
import 'package:cable_billing_app/Database/db_helper.dart';
import 'add_customer_screen.dart';
import 'customer_list_screen.dart';
import 'billing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalCustomers = 0;
  int _pendingBills = 0;
  double _totalIncome = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // 1. Fetch all the data for the Command Center
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      DateTime now = DateTime.now();
      List<String> monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
      String currentMonth = '${monthNames[now.month - 1]} ${now.year}';

      final customers = await DatabaseHelper.instance.getAllCustomers();
      final stats = await DatabaseHelper.instance.getMonthlyBillStats(currentMonth);
      final income = await DatabaseHelper.instance.getMonthlyIncome(currentMonth);

      setState(() {
        _totalCustomers = customers.length;
        _pendingBills = stats['unpaid'] ?? 0;
        _totalIncome = income;
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      // If ANYTHING goes wrong, stop the loading circle and show the exact error!
      setState(() => _isLoading = false);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('CRITICAL STARTUP ERROR', style: TextStyle(color: Colors.red)),
            content: SingleChildScrollView(
              child: Text('Please take a photo of this and send it to the developer:\n\n$e\n\n$stackTrace'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK')
              )
            ],
          ),
        );
      }
    }
  }

  // 2. A reusable widget for our polished Statistics Cards
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  Icon(icon, color: color, size: 30),
                ],
              ),
              const SizedBox(height: 15),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // 3. A reusable widget for our Quick Action Buttons
  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Card(
          color: color.withOpacity(0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.5))),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            child: Column(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 10),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // --- NEW: Backup Menu Logic ---
  void _showBackupMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Disaster Recovery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // CREATE BACKUP BUTTON
              ListTile(
                leading: const Icon(Icons.backup, color: Colors.blue, size: 30),
                title: const Text('Create Backup File'),
                subtitle: const Text('Save a copy of your data to a safe location.'),
                onTap: () async {
                  Navigator.pop(context); // Close the menu

                  String? path = await DatabaseHelper.instance.backupDatabase();

                  if (path != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Backup Saved Successfully to:\n$path'), duration: const Duration(seconds: 4)),
                    );
                  }
                },
              ),
              const Divider(),

              // RESTORE DATA BUTTON
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.red, size: 30),
                title: const Text('Restore from Backup', style: TextStyle(color: Colors.red)),
                subtitle: const Text('WARNING: This will overwrite current data.'),
                onTap: () async {
                  Navigator.pop(context); // Close the menu

                  bool success = await DatabaseHelper.instance.restoreDatabase();

                  if (success) {
                    // Reload the dashboard numbers because the data just completely changed!
                    _loadDashboardData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Database Restored Successfully!'), backgroundColor: Colors.green),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // A slightly off-white background makes the white cards pop
      appBar: AppBar(
        title: const Text('Billing Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Text('Business Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('Current Month Data', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 20),

            // --- STATISTICS ROW ---
            Row(
              children: [
                _buildStatCard('Total Customers', '$_totalCustomers', Icons.people, Colors.blue),
                const SizedBox(width: 20),
                _buildStatCard('Pending Bills', '$_pendingBills', Icons.warning_amber_rounded, Colors.orange),
                const SizedBox(width: 20),
                _buildStatCard('Total Income', 'Rs. $_totalIncome', Icons.account_balance_wallet, Colors.green),
              ],
            ),
            const SizedBox(height: 40),

            // --- QUICK ACTIONS HEADER ---
            const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // --- ACTIONS ROW ---
            Row(
              children: [
                _buildActionButton('Add Customer', Icons.person_add, Colors.blue, () {
                  // We use .then() so when the user comes back to this screen, it refreshes the data!
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCustomerScreen()))
                      .then((_) => _loadDashboardData());
                }),
                const SizedBox(width: 20),

                _buildActionButton('Manage Customers', Icons.group, Colors.indigo, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerListScreen()))
                      .then((_) => _loadDashboardData());
                }),
                const SizedBox(width: 20),

                _buildActionButton('Billing & Payments', Icons.receipt_long, Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BillingScreen()))
                      .then((_) => _loadDashboardData());
                }),

                const SizedBox(width: 20),
                _buildActionButton('Data Backup', Icons.save_alt, Colors.deepPurple, () => _showBackupMenu(context)),


              ],
            ),
          ],
        ),
      ),
    );
  }
}