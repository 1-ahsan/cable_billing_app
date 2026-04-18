import 'package:cable_billing_app/Database/db_helper.dart';
import 'package:cable_billing_app/Models/Bill.dart';
import 'package:cable_billing_app/Models/Customer.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  final DatabaseHelper db = DatabaseHelper.instance;

  void _printCustomers() async{
    List<Customer> list = await db.getAllCustomers();

    // print(list[0].toString());
    // list.forEach((c)=>print(c.toString()));
    for(var c in list){
      print(c.toString());
    }
  }

  void _deleteCustomer() async{
    int id = 1;
    // final x = await db.deleteCustomer(id);
    // print("x = ${x}");
  }

  void _pintBills() async{
    List<Bill> bils = await db.getAllBills();

    for(var b in bils){
      print(b.toString());
    }
  }

  void _printBillByMonth() async{
    List<Bill> bils = await db.getBillsByMonth("April");

    for(var b in bils){
      print(b.toString());
    }
  }

  void _payBill() async{
    int bils = await db.markBillAsPaid(2);

    print(bils);
  }

  void _printUnpaidBills() async{
    Map<String, int> ab = await db.getMonthlyBillStats("April");

    print(ab['paid']);  // 0
    print(ab['unpaid']); // 2
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: (){
                Customer customer = Customer(
                  name: "Ahsan",
                  idCardNumber: "idCardNumber",
                  address: "address",
                  serviceType: "serviceType",
                  monthlyFee: 200,
                  connectionDate: "Unknown",
                  connectionCode: "Unknown",
                  isActive: 1,
                  fatherName: "Ghulam",
                );
                db.insertCustomer(customer);
                print("customer added");
              },
              child: Text("Add"),
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: (){
                _printCustomers();
              },
              child: Text("Read"),
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: (){
                Customer customer = Customer(
                  name: "Ahsan",
                  idCardNumber: "000000",
                  address: "address",
                  serviceType: "serviceType",
                  monthlyFee: 200,
                  customerId: 2,
                  connectionDate: "Unknown",
                  connectionCode: "Unknown",
                  isActive: 1,
                  fatherName: "Ghulam",
                );
                db.updateCustomer(customer);
                print("Updated");
              },
              child: Text("Update"),
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: (){
                // db.deleteCustomer(3);
                _deleteCustomer();
                print("Deleted");
              },
              child: Text("Delete"),
            ),
            SizedBox(height: 30,),
            ElevatedButton(
              onPressed: (){
                Bill bill = Bill(customerId: 0, billingMonth: "April", amountDue: 1800);
                db.insertBill(bill);
                print("Bill added");
              },
              child: Text("Add Bill"),
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: (){
                _pintBills();
              },
              child: Text("Read Bill"),
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: (){
                _printBillByMonth();
              },
              child: Text("Bill of a month"),
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: (){
                _payBill();
                print("paid");
              },
              child: Text("pay bill"),
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: (){
                _printUnpaidBills();
              },
              child: Text("Get bill static"),
            ),
          ],
        ),
      ),
    );
  }

}

