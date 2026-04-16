import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:cable_billing_app/Models/Customer.dart';
import 'package:cable_billing_app/Models/Bill.dart';



class DatabaseHelper {
  // This creates a "Singleton" so you don't accidentally open 10 database connections at once
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('billing_app.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {

    // 2. Find where to save the file on the computer
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    // 3. Open the database and create tables
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => _createDB(db, version)

    );
  }

  // 4. THE SQL: Writing the actual database schema
  Future _createDB(Database db, int version) async {

    // Create Customers Table
    await db.execute('''
      CREATE TABLE customers (
        customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        id_card_number TEXT NOT NULL,
        contact_info TEXT,
        address TEXT NOT NULL,
        service_type TEXT NOT NULL, 
        monthly_fee REAL NOT NULL
      )
    ''');

    // Create Bills Table
    await db.execute('''
      CREATE TABLE bills (
        bill_id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        billing_month TEXT NOT NULL,
        amount_due REAL NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE CASCADE
      )
    ''');

    print("Database Created");

    // Note: is_paid uses INTEGER (0 for Unpaid, 1 for Paid) because SQLite does not have a boolean type.
  }


  // ==========================================
  // CUSTOMER CRUD OPERATIONS
  // ==========================================

  // CREATE: Add a new customer
  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    // We pass the table name 'customers' and use our model's toMap() translator
    return await db.insert('customers', customer.toMap());
  }

  // READ: Get a list of all customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    // Query the table for all rows
    final List<Map<String, dynamic>> maps = await db.query('customers');

    // Convert the List of raw database Maps into a List of Customer objects
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // UPDATE: Change a customer's details (like their address or fee)
  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'customer_id = ?', // ? is a security feature to prevent hacking
      whereArgs: [customer.customerId], // It safely injects the ID here
    );
  }

  // DELETE: Remove a customer entirely
  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete(
      'customers',
      where: 'customer_id = ?',
      whereArgs: [id],
    );
  }



  // ==========================================
  // BILL CRUD OPERATIONS
  // ==========================================

  // CREATE: Generate a new bill for a customer
  Future<int> insertBill(Bill bill) async {
    final db = await instance.database;
    return await db.insert('bills', bill.toMap());
  }

  // Get All bills
  Future<List<Bill>> getAllBills() async{
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      "bills",
    );
    return List.generate(maps.length, (i){
      return Bill.fromMap(maps[i]);
    });
  }

  // READ: Get all bills for a specific month (e.g., "May 2026")
  Future<List<Bill>> getBillsByMonth(String month) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: 'billing_month = ?',
      whereArgs: [month],
    );

    return List.generate(maps.length, (i) {
      return Bill.fromMap(maps[i]);
    });
  }

  // UPDATE: Mark a specific bill as Paid (changes is_paid from 0 to 1)
  Future<int> markBillAsPaid(int billId) async {
    final db = await instance.database;
    return await db.update(
      'bills',
      {'is_paid': 1}, // We only want to update this one specific column
      where: 'bill_id = ?',
      whereArgs: [billId],
    );
  }

  // UPDATE: Mark a bill as Unpaid (changes is_paid from 1 back to 0)
  Future<int> markBillAsUnpaid(int billId) async {
    final db = await instance.database;
    return await db.update(
      'bills',
      {'is_paid': 0}, // Sets it back to unpaid
      where: 'bill_id = ?',
      whereArgs: [billId],
    );
  }

  // ==========================================
  // ADVANCED: GET BILLS WITH CUSTOMER DETAILS
  // ==========================================
  Future<List<Map<String, dynamic>>> getBillsWithCustomerDetails(String month) async {
    final db = await instance.database;

    // We use a raw SQL JOIN to combine two tables into one result!
    return await db.rawQuery('''
      SELECT 
        bills.*, 
        customers.name, 
        customers.contact_info, 
        customers.address 
      FROM bills
      INNER JOIN customers ON bills.customer_id = customers.customer_id
      WHERE bills.billing_month = ?
    ''', [month]);
  }

  // Get all bills for a single customer (Sorted newest first)
  Future<List<Map<String, dynamic>>> getCustomerBillingHistory(int customerId) async {
    final db = await instance.database;

    return await db.rawQuery('''
      SELECT 
        bills.*, 
        customers.name, 
        customers.contact_info, 
        customers.address 
      FROM bills
      INNER JOIN customers ON bills.customer_id = customers.customer_id
      WHERE bills.customer_id = ?
      ORDER BY bills.bill_id DESC 
    ''', [customerId]);
    // NOTE: We order by bill_id DESC. Since IDs auto-increment, the highest ID is always the most recent month!
  }


  // ==========================================
  // DASHBOARD STATISTICS
  // ==========================================

  // Get total counts of Paid and Unpaid bills for a specific month
  Future<Map<String, int>> getMonthlyBillStats(String month) async {
    final db = await instance.database;

    // Count unpaid bills (is_paid = 0)
    final unpaidResult = await db.rawQuery(
        'SELECT COUNT(*) FROM bills WHERE billing_month = ? AND is_paid = 0',
        [month]
    );
    int unpaidCount = Sqflite.firstIntValue(unpaidResult) ?? 0;

    // Count paid bills (is_paid = 1)
    final paidResult = await db.rawQuery(
        'SELECT COUNT(*) FROM bills WHERE billing_month = ? AND is_paid = 1',
        [month]
    );

// Debug
//
// final List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM bills WHERE billing_month =? And is_paid = 0",
//   [month]
// );
//
// for(var b in maps){
//   print(b.toString());
// }

    int paidCount = Sqflite.firstIntValue(paidResult) ?? 0;

    return {'unpaid': unpaidCount, 'paid': paidCount};
  }

  // Calculate total income (Sum of amount_due for all PAID bills this month)
  Future<double> getMonthlyIncome(String month) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT SUM(amount_due) FROM bills WHERE billing_month = ? AND is_paid = 1',
        [month]
    );

    // If there is no income yet, return 0.0
    if (result.first.values.first == null) {
      return 0.0;
    }
    return (result.first.values.first as num).toDouble();
  }


}