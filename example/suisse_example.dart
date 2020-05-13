import 'dart:convert';
import 'package:suisse/suisse.dart';

//ignore_for_file: avoid_print

Future<void> main(List<String> args) async {
  var client = Client('https://test-paymentterminal.bitcoinsuisse.ch', args[0]);
  var payment = Payment()
    ..merchantNumber = args[1]
    ..terminalNumber = args[2]
    ..amount = 100
    ..fromCurrency = 'CHF'
    ..toCurrency = 'BTC';

  var response = await client.createPayementRequest(payment);
  var body = json.decode(response.body);

  response = await client.isChanged(body['Key']);
  print(response.body);
}
