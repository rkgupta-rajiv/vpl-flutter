// Adds the platform permissions this app needs.
// Run AFTER `flutter create .` (works on Windows, macOS, Linux):
//
//   flutter create . --project-name vpl_player --org com.webcreta --platforms=android,ios,web
//   dart run tool/setup_platforms.dart
//
// Android: INTERNET permission, cleartext HTTP (for local testing), <queries> for UPI apps.
// iOS: camera / photo library usage strings, UPI URL schemes.
import 'dart:io';

void main() {
  _android();
  _ios();
  stdout.writeln('\nDone. Now run: flutter pub get && flutter run');
}

void _android() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) {
    stdout.writeln('! android/ not found — run `flutter create .` first.');
    return;
  }
  var xml = f.readAsStringSync();

  if (!xml.contains('android.permission.INTERNET')) {
    xml = xml.replaceFirst(RegExp(r'<manifest[^>]*>'), '${RegExp(r'<manifest[^>]*>').firstMatch(xml)!.group(0)}\n    <uses-permission android:name="android.permission.INTERNET"/>');
  }
  if (!xml.contains('usesCleartextTraffic')) {
    // Allows http:// API URLs while testing locally. Remove for production (use https).
    xml = xml.replaceFirst('<application', '<application\n        android:usesCleartextTraffic="true"');
  }
  const queries = '''
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="upi" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>''';
  if (!xml.contains('android:scheme="upi"')) {
    if (xml.contains('<queries>')) {
      xml = xml.replaceFirst('<queries>', '<queries>\n        <intent>\n            <action android:name="android.intent.action.VIEW" />\n            <data android:scheme="upi" />\n        </intent>');
    } else {
      xml = xml.replaceFirst('</manifest>', '$queries\n</manifest>');
    }
  }
  f.writeAsStringSync(xml);
  stdout.writeln('✓ AndroidManifest.xml updated');
}

void _ios() {
  final f = File('ios/Runner/Info.plist');
  if (!f.existsSync()) {
    stdout.writeln('- ios/ not found (skipped)');
    return;
  }
  var plist = f.readAsStringSync();
  final entries = <String, String>{
    'NSCameraUsageDescription': '<string>Take your profile photo, Aadhaar card and payment screenshot.</string>',
    'NSPhotoLibraryUsageDescription': '<string>Choose your profile photo, Aadhaar card and payment screenshot.</string>',
    'LSApplicationQueriesSchemes': '<array>\n\t\t<string>upi</string>\n\t\t<string>phonepe</string>\n\t\t<string>tez</string>\n\t\t<string>paytmmp</string>\n\t</array>',
  };
  final buf = StringBuffer();
  entries.forEach((k, v) {
    if (!plist.contains('<key>$k</key>')) buf.write('\t<key>$k</key>\n\t$v\n');
  });
  if (buf.isNotEmpty) {
    final idx = plist.lastIndexOf('</dict>');
    plist = plist.substring(0, idx) + buf.toString() + plist.substring(idx);
    f.writeAsStringSync(plist);
  }
  stdout.writeln('✓ Info.plist updated');
}
