import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mock_web_server/mock_web_server.dart';

import 'package:suisse/suisse.dart';

MockWebServer server;
Client client;
String secret;
const String sharedSecret = "some shared secret";
const String merchantNumber = "some merchant number";
const String terminalNumber = "some terminal number";
const String paymentNumber = "some payment number";

void main() {
  setUp(() async {
    server = MockWebServer();
    await server.start();
    client = Client(server.url, "some shared secret");
  });

  test('initialization', () {
    expect(client, isNotNull);
  });

  group('getMerchant', () {
    setUp(() async {
      var cannedResponse =
          await File('test/files/get_merchant.json').readAsString();
      server.enqueue(body: cannedResponse);
    });

    test('adds the correct hash', () async {
      await client.getMerchant(terminalNumber);
      var request = server.takeRequest();

      // hash calculated with `echo -n 'some terminal numbersome shared secret' | sha256sum -`
      expect(
        json.decode(request.body)["Hash"],
        equals(
            "4768ecd6b30c1f4a7188efe8d583ce20acb5d3c9efa7b2a0fb0bfdedcca1b682"),
      );
    });

    test('returns a bunch of configuration fields', () async {
      var response = await client.getMerchant(terminalNumber);
      expect(json.decode(response.body)["MerchantName"], equals("Inacta"));
    });
  });

  group('createPaymentRequest', () {
    Payment payment;
    setUp(() async {
      payment = Payment()
        ..merchantNumber = merchantNumber
        ..terminalNumber = terminalNumber
        ..amount = 100
        ..description = "some description"
        ..fromCurrency = "CHF"
        ..toCurrency = "BTC";

      var cannedResponse =
          await File('test/files/create_payment_request.json').readAsString();
      server.enqueue(body: cannedResponse);
    });

    test('creates a correct hash', () async {
      await client.createPayementRequest(payment);
      var request = server.takeRequest();

      expect(
          json.decode(request.body)["Hash"],
          equals(
              "7bdf8561df1f3cf8ab575a283f237cbd4d73be564dff2d0efce72fc0a7fb50b6"));
    });

    test('returns a identifier for later reference', () async {
      var response = await client.createPayementRequest(payment);

      expect(json.decode(response.body)["Key"], isNotNull);
    });

    test('returns a URL for the QR code', () async {
      var response = await client.createPayementRequest(payment);

      expect(Uri.parse(json.decode(response.body)["QRData"]).scheme, "bitcoin");
    });

    test('returns amount of satoshis to be paid', () async {
      var response = await client.createPayementRequest(payment);

      expect(json.decode(response.body)["CCAmount"], 20063);
    });
  });

  group('getPaymentRequest', () {
    setUp(() async {
      var cannedResponse =
          await File('test/files/get_payment_request.json').readAsString();
      server.enqueue(body: cannedResponse);
    });

    test('return a map with stuff', () async {
      var response = await client.getPaymentRequest(paymentNumber);
      expect(json.decode(response.body), isMap);
    });

    test('includes a hash in the request', () async {
      await client.getPaymentRequest(paymentNumber);

      var request = server.takeRequest();
      expect(json.decode(request.body).keys, containsAll(["Key", "Hash"]));
    });
  });

  group('updatePaymentRequest', () {});

  group('isChanged', () {
    setUp(() async {
      var cannedResponse =
          await File('test/files/is_changed.json').readAsString();
      server.enqueue(body: cannedResponse);
    });

    test('creates a simple GET request', () async {
      await client.isChanged("some key");
      var request = server.takeRequest();

      expect(request.uri.query, "Key=some+key");
    });

    test('returns a simple hash', () async {
      var response = await client.isChanged("some key");

      expect(json.decode(response.body), equals({"returnValue": false}));
    });
  });
}
