import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for handling secure local storage.
/// We use FlutterSecureStorage for sensitive user data and SharedPreferences for basic preferences.
class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  
  static const String _keyUserId = 'user_id';
  static const String _keyUserCategory = 'user_category';
  static const String _keyUserData = 'user_data';
  static const String _keyDarkMode = 'dark_mode';

  /// Save user ID securely
  static Future<void> saveUserId(int userId) async {
    await _secureStorage.write(key: _keyUserId, value: userId.toString());
  }

  /// Get user ID from secure storage
  static Future<int?> getUserId() async {
    final value = await _secureStorage.read(key: _keyUserId);
    return value != null ? int.tryParse(value) : null;
  }

  /// Save user category securely
  static Future<void> saveUserCategory(String category) async {
    await _secureStorage.write(key: _keyUserCategory, value: category);
  }

  /// Get user category from secure storage
  static Future<String?> getUserCategory() async {
    return await _secureStorage.read(key: _keyUserCategory);
  }

  /// Save user data JSON securely
  static Future<void> saveUserData(String userDataJson) async {
    await _secureStorage.write(key: _keyUserData, value: userDataJson);
  }

  /// Get user data JSON from secure storage
  static Future<String?> getUserData() async {
    return await _secureStorage.read(key: _keyUserData);
  }

  /// Set dark mode preference using SharedPreferences
  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
  }

  /// Get dark mode preference
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  /// Clear all sensitive data on logout
  static Future<void> clearAll() async {
    await _secureStorage.delete(key: _keyUserId);
    await _secureStorage.delete(key: _keyUserCategory);
    await _secureStorage.delete(key: _keyUserData);
  }
}

