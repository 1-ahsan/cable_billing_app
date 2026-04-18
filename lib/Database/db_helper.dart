import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:cable_billing_app/Models/Customer.dart';
import 'package:cable_billing_app/Models/Bill.dart';

import 'package:path_provider/path_provider.dart';

import 'dart:io'; // Needed to copy and paste files
import 'package:file_picker/file_picker.dart'; // Needed for the popup windows


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

  Future<Database> _initDB(String filePath) async {
    // --- NEW PRODUCTION PATH LOGIC ---
    // 1. Find the computer's official Documents folder
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    // 2. Create a dedicated folder just for your app inside Documents
    String appFolderPath = join(documentsDirectory.path, 'cable_billing_app');

    // 3. If that folder doesn't exist yet, create it
    await Directory(appFolderPath).create(recursive: true);

    // 4. Set the final path for the .db file
    final path = join(appFolderPath, filePath);
    // ---------------------------------

    return openDatabase(
      path,
      version: 3, // updated to 2 - 3
      onCreate: (db, version) => _createDB(db, version),
      onUpgrade: _upgradeDB,
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
        monthly_fee REAL NOT NULL,
        connection_date TEXT NOT NULL, -- Added here for new installs
        connection_code TEXT NOT NULL, -- new update 2
        is_active INTEGER DEFAULT 1, -- Added for brand new installs
        father_name TEST DEFAULT "Unknown"
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

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // ALTER TABLE injects a new column into the existing file safely
      await db.execute('ALTER TABLE customers ADD COLUMN connection_date TEXT DEFAULT "Unknown"');
      await db.execute('ALTER TABLE customers ADD COLUMN connection_code Text DEFAULT "Unknown"');
      await db.execute('ALTER TABLE customers ADD COLUMN is_active INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE customers ADD COLUMN TEXT father_name DEFAULT "Unknown"');
    }
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
  // Now accepts a filter. If filter is null, it returns everyone.
  // If filter is 1, returns Active. If 0, returns Inactive.
  Future<List<Customer>> getAllCustomers({int? activeFilter}) async {
    final db = await instance.database;

    String? whereClause;
    List<Object?>? whereArgs;

    if (activeFilter != null) {
      whereClause = 'is_active = ?';
      whereArgs = [activeFilter];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'customer_id DESC', // Newest first
    );

    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
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

  Future<int> deactivateCustomer(int id) async {
    final db = await instance.database;
    final temp = await db.rawQuery('''
    SELECT is_active FROM customers WHERE customer_id == ?
    ''',[id]);
    int isActive = temp[0]['is_active'] as int;
    if(isActive == 1){
      return await db.update(
        'customers',
        {'is_active': 0},
        where: 'customer_id = ?',
        whereArgs: [id],
      );
    }

    return await db.update(
      'customers',
      {'is_active': 1},
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



  // ==========================================
  // DISASTER RECOVERY & BACKUPS
  // ==========================================

  // 1. Safely close the database connection
  Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null; // Resets it so it re-opens fresh next time
    }
  }

  // 2. Generate a Backup File
  Future<String?> backupDatabase() async {
    try {
      final db = await instance.database;
      final originalDbPath = db.path;

      // Opens a Windows/Mac "Save As" window
      String? destinationPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName: 'CabelBillingAppBackup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.db',
      );

      // If the admin picked a location and didn't click cancel
      if (destinationPath != null) {
        File sourceFile = File(originalDbPath);
        await sourceFile.copy(destinationPath); // Copies the file to the USB/Desktop
        return destinationPath; // Returns the path for our success message
      }
    } catch (e) {
      print("Backup Error: $e");
    }
    return null; // Means the user canceled or an error occurred
  }

  // 3. Restore from a Backup File
  Future<bool> restoreDatabase() async {
    try {
      // Opens a Windows/Mac "Select File" window
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup File to Restore',
        type: FileType.any, // Allows them to pick the .db file
      );

      // If the admin picked a file
      if (result != null && result.files.single.path != null) {
        String backupFilePath = result.files.single.path!;

        // Step A: Get the current path where the app expects the database to be
        final db = await instance.database;
        final currentDbPath = db.path;

        // Step B: CLOSE the database connection. (You cannot overwrite an open file!)
        await closeDatabase();

        // Step C: Delete the current database and copy the backup file into its place
        File backupFile = File(backupFilePath);
        await backupFile.copy(currentDbPath);

        // Step D: We return true, and the next time the app asks for the database,
        // it will automatically open the newly restored file!
        return true;
      }
    } catch (e) {
      print("Restore Error: $e");
    }
    return false;
  }


}