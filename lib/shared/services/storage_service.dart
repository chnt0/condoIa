import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  // Token methods (secure storage)
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<void> clearToken() async {
    await deleteToken();
  }

  // User methods (shared preferences)
  Future<void> saveUser(Usuario user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(AppConstants.userKey, userJson);
  }

  Future<Usuario?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);

    if (userJson == null) {
      return null;
    }

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return Usuario.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
  }

  Future<void> clearUser() async {
    await deleteUser();
  }

  // Clear all stored data
  Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}
