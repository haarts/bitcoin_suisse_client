import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:suisse/suisse.dart';

main(List<String> args) async {
  var client = Client("https://test-paymentterminal.bitcoinsuisse.ch", args[0]);
  var payment = Payment()
    ..merchantNumber = "EC66F139"
    ..terminalNumber = "T53NF5"
    ..amount = 100
    ..fromCurrency = "CHF"
    ..toCurrency = "BTC";

  http.Response response = await client.createPayementRequest(payment);
  var body = json.decode(response.body);

  response = await client.isChanged(body["Key"]);
  print(response.body);
}
