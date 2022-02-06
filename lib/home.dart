import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController amt = new TextEditingController();

  Map<String , dynamic>? paymentIntentData;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stripe Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("7\$"),
            ElevatedButton(onPressed: ()async{
              await makePayment();
            }, child: Text('Pay'))
          ],
        ),
      ),
    );

  }
  Future<void> makePayment()async{
    try{
      paymentIntentData = await createPaymentIntent("7", "EUR");
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              googlePay: true,
              applePay: true,
              style: ThemeMode.dark,
              merchantCountryCode: 'IT',
              merchantDisplayName: 'Indiano'
          )
      );

      displayPaymentSheet();
    }catch(e){
      print(e.toString());
    }
  }
  displayPaymentSheet() async{
    try{
      await Stripe.instance.presentPaymentSheet(
          parameters: PresentPaymentSheetParameters(
            clientSecret: paymentIntentData!['client_secret'],
            confirmPayment: true,
          )
      );
      setState(() {
        paymentIntentData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("paid successfully")));
    }on StripeException catch(e){
      print(e.toString());
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Text("Cancelled "),
          ));
    }
  }
  createPaymentIntent(String amt, String cur) async{
    try{
      Map<String , dynamic> body = {
        'amount' : calculateAmount(amt),
        'currency' : cur,
        'payment_method_types[]' : 'card'
      };

      var response = await http.post(Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization' : 'Bearer sk_test_51KNzy3Cov4UDqXfm6cP6Wur7HmvN75jIlEmCBWmhQmIRpZRIenDJCASkty41PnVRmwi2RvLKTDuMvSPPra9E7Y0T00SOyf6qrK',
            'content-Type' : 'application/x-www-form-urlencoded'
          }
      );
      return jsonDecode(response.body.toString());

    }catch(e){
      print(e.toString());
    }
  }
  calculateAmount(String amt){
    final price = int.parse(amt) * 100;
    return price.toString();
  }
}
