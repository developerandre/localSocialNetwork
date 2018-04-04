import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:localsocialnetwork/utils.dart';


Future<http.Response> getCode(String phoneNumber) => http.get(
    new Uri.https(HOST, 'api/public/code_confirmation', {'phone': phoneNumber})
);

Future<http.Response> getPassword(String phoneNumber, String code) => http.get(
    new Uri.https(HOST, 'api/public/verifier_code_confirmation', {
        'phone': phoneNumber,
        'code': code,
    })
);
