import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Network Security Config file should exist and block cleartext traffic', () {
    final file = File('android/app/src/main/res/xml/network_security_config.xml');
    expect(file.existsSync(), isTrue, reason: 'network_security_config.xml missing');
    
    final content = file.readAsStringSync();
    expect(content, contains('cleartextTrafficPermitted="false"'), reason: 'Should block cleartext traffic by default');
    expect(content, contains('<debug-overrides>'), reason: 'Should have debug overrides');
  });

  test('AndroidManifest should reference network security config', () {
    final file = File('android/app/src/main/AndroidManifest.xml');
    expect(file.existsSync(), isTrue, reason: 'AndroidManifest.xml missing');
    
    final content = file.readAsStringSync();
    expect(content, contains('android:networkSecurityConfig="@xml/network_security_config"'), reason: 'Manifest missing networkSecurityConfig reference');
    expect(content, contains('android:usesCleartextTraffic="false"'), reason: 'Manifest should explicitly set usesCleartextTraffic to false');
  });
}
