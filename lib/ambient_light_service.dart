import 'package:flutter/services.dart';

class AmbientLightService {
  static const MethodChannel _methods = MethodChannel('dnbplantai/light_sensor');
  static const EventChannel _events = EventChannel('dnbplantai/light_stream');

  static Future<bool> hasSensor() async {
    return await _methods.invokeMethod<bool>('hasSensor') ?? false;
  }

  static Stream<double> luxStream() {
    return _events.receiveBroadcastStream().map((value) => (value as num).toDouble());
  }
}
