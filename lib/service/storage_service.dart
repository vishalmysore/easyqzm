import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../util/debug.dart' as debug;
class StorageService {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  // Store data in secure storage
  Future<void> store({required String key, required  String value}) async {
    try {
      await storage.write(key: key, value: value);
      debug.d('Stored $key successfully');
    } catch (error) {
      debug.d('Error storing $key: $error');
    }
  }

  // Retrieve data from secure storage
  Future<String?> retrieve({required String key}) async {
    try {
      String? value = await storage.read(key: key);
      debug.d('Retrieved $key: $value');
      return value;
    } catch (error) {
      debug.d('Error retrieving $key: $error');
      return null;
    }
  }
}
