// .../utils/common_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CommonUtils {
  static final _storage = FlutterSecureStorage();

  static Future<void> waitForMilliseconds(int milliseconds) async { // Mostly use seconds, but this is more dynamic (as there are areas I use < 1 second)
    await Future.delayed(Duration(milliseconds: milliseconds));
  }
}
