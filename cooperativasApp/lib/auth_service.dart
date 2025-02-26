import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database/database_helper.dart';
import '../cooperative_service.dart';

class User {
  final int id;
  final String email;
  final String name;

  User({required this.id, required this.email, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      email: map['email'],
      name: map['name'],
    );
  }
}

class AuthService with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<bool> register(String email, String password, String name) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.228.32:3000/usuarios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'name': name, 'password': password}),
      );

      if (response.statusCode != 200) {
        print('Error al crear usuario en el servidor');
        return false;
      }

      final userData = jsonDecode(response.body);
      final newUser = User(
        id: userData['id'],
        email: email,
        name: name,
      );

      await _dbHelper.insertUsuario(newUser);

      _currentUser = newUser;
      notifyListeners();
      await syncWithServer();
      return true;
    } catch (e) {
      print('Error en register: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // Intenta autenticar con el servidor primero
      final response = await http.post(
        Uri.parse('http://192.168.228.32:3000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final user = User(
          id: userData['user']['id'],
          email: userData['user']['email'],
          name: userData['user']['name'],
        );

        // Actualiza el usuario local
        await _dbHelper.insertUsuario(user);

        _currentUser = user;
        notifyListeners();

        // Sincroniza los datos
        await syncWithServer();

        // Sincroniza las cooperativas
        await CooperativeService().syncWithServer();
        await CooperativeService().loadMiembrosFromServer();

        return true;
      } else {
        print('Error en login: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  Future<void> syncWithServer() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.228.32:3000/usuarios'));
      if (response.statusCode == 200) {
        final List<dynamic> serverUsers = jsonDecode(response.body);
        for (var userData in serverUsers) {
          final user = User(
            id: userData['id'],
            email: userData['email'],
            name: userData['name'],
          );
          await _dbHelper.insertUsuario(user);
        }
      }
    } catch (e) {
      print('Error en syncWithServer: $e');
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
