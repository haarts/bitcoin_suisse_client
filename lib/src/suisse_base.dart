import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class Payment {
  String merchantNumber;
  String terminalNumber;
  int amount; // in cents, 100 = 1 EUR/CHF/...
  String description;
  String reference;
  String email;
  String fromCurrency;
  String toCurrency;
  Uri declineUrl;
  Uri acceptUrl;
  Uri callbackUrl;

  String hash;

  String toJson() {
		return json.encode(
  		{
    		"Amount": amount,
    		"TerminalNumber": terminalNumber,
    		"MerchantNumber": merchantNumber,
				"Description": description,
				"Reference": reference,
				"Email": email,
				"FromCurrency": fromCurrency,
				"ToCurrency": toCurrency,
				"DeclineUrl": declineUrl,
				"AcceptUrl": acceptUrl,
				"CallbackUrl": callbackUrl,
				"Hash": hash,
  		}
		);
  }
}

class Client {
  final Uri _url;
  final String _secret;
  final http.Client _client;
  static const Map<String, String> _headers = {
    HttpHeaders.userAgentHeader: "Bitcoin Suisse - Dart",
    HttpHeaders.contentTypeHeader: 'application/json',
  };

  Client(String url, this._secret)
      : this._url = Uri.parse(url),
        this._client = http.Client();

  Future<http.Response> getMerchant(String terminalNumber) async {
    String hash = _hash("$terminalNumber$_secret");
    return await _client.post(
      _url.replace(path: "/api/GetMerchant"),
      body: json.encode({"Key": terminalNumber, "Hash": hash}),
      headers: _headers,
    );
  }

  Future<http.Response> getPaymentRequest(String paymentNumber) async {
    String hash = _hash("$paymentNumber$_secret");
    return await _client.post(
      _url.replace(path: "/api/GetPaymentRequest"),
      body: json.encode({"Key": paymentNumber, "Hash": hash}),
      headers: _headers,
    );
  }

  Future<http.Response> createPayementRequest(Payment payment) async {
    String hash = _hash(
        "${payment.merchantNumber}${payment.terminalNumber}${payment.amount}${payment.fromCurrency}${payment.toCurrency}$_secret");
    payment.hash = hash;
    return await _client.post(
      _url.replace(path: "/api/CreatePaymentRequest"),
      body: payment.toJson(),
      headers: _headers,
    );
  }

  String _hash(String input) {
    var bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
