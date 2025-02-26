import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database/database_helper.dart';

class Cooperative {
  final String id;
  final String name;
  final String description;
  List<Member> members;

  Cooperative({
    required this.id,
    required this.name,
    required this.description,
    List<Member>? members,
  }) : members = members ?? [];

  // Convertir Cooperative a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  // Convertir Map a Cooperative
  static Cooperative fromMap(Map<String, dynamic> map) {
    return Cooperative(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }
}

class Member {
  final String userId;
  double balance;

  Member({required this.userId, this.balance = 0.0});

  // Convertir Member a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
    };
  }
}

class CooperativeService with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Obtener cooperativas desde SQLite
  Future<List<Cooperative>> get cooperatives async {
    return await _dbHelper.getCooperativas();
  }

  // Crear cooperativa (local y servidor)
  Future<void> createCooperative(String name, String description) async {
    try {
      final newCooperative = Cooperative(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
      );

      // Guardar en SQLite
      await _dbHelper.insertCooperative(newCooperative);

      // Sincronizar con servidor
      final response = await http.post(
        Uri.parse('http://192.168.228.32:3000/cooperativas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newCooperative.toMap()),
      );

      if (response.statusCode != 200) {
        print('Error al sincronizar con el servidor');
      }

      notifyListeners();
    } catch (e) {
      print('Error en createCooperative: $e');
    }
  }

  Future<void> syncMiembros() async {
    try {
      final miembros = await _dbHelper.getAllMiembros();
      final response = await http.post(
        Uri.parse('http://192.168.228.32:3000/sync-miembros'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'miembros': miembros.map((m) => m.toMap()).toList()}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al sincronizar miembros');
      }

      print('Miembros sincronizados exitosamente');
    } catch (e) {
      print('Error al sincronizar miembros: $e');
    }
  }

  Future<void> leaveCooperative(String cooperativeId, String userId) async {
    try {
      // Eliminar el miembro de la base de datos local
      await _dbHelper.deleteMiembro(cooperativeId, userId);

      // Sincronizar con el servidor
      final response = await http.post(
        Uri.parse('http://192.168.228.32:3000/leave-cooperative'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cooperativeId': cooperativeId,
          'userId': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al abandonar la cooperativa en el servidor');
      }

      // Sincronizar miembros después de abandonar
      await syncMiembros();

      notifyListeners();
    } catch (e) {
      print('Error en leaveCooperative: $e');
    }
  }

  Future<List<Cooperative>> getCooperativas() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getCooperativas();
  }

  // Unirse a cooperativa
  Future<void> joinCooperative(String cooperativeId, String userId) async {
    try {
      final newMember = Member(userId: userId, balance: 100.0);

      // Guardar en SQLite
      await _dbHelper.insertMiembro(newMember, cooperativeId);

      // Sincronizar con servidor
      final response = await http.post(
        Uri.parse('http://192.168.228.32:3000/miembros'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cooperativeId': cooperativeId,
          'member': newMember.toMap(),
        }),
      );

      if (response.statusCode != 200) {
        print('Error al sincronizar membresía');
      }

      notifyListeners();
    } catch (e) {
      print('Error en joinCooperative: $e');
    }
  }

  Future<void> loadMiembrosFromServer() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.228.32:3000/miembros'));
      if (response.statusCode == 200) {
        final List<dynamic> serverData = jsonDecode(response.body);
        for (var miembroData in serverData) {
          final miembro = Member(
            userId: miembroData['userId'],
            balance: miembroData['balance'].toDouble(),
          );
          await _dbHelper.insertMiembro(miembro, miembroData['cooperativeId']);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error al cargar miembros desde el servidor: $e');
    }
  }

  // Sincronizar datos con el servidor
  Future<void> syncWithServer() async {
    try {
      // Enviar cooperativas locales al servidor
      final localCooperativas = await cooperatives;
      await http.post(
        Uri.parse('http://192.168.228.32:3000/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cooperativas': localCooperativas.map((c) => c.toMap()).toList(),
        }),
      );

      // Obtener cooperativas actualizadas del servidor
      final response =
          await http.get(Uri.parse('http://192.168.228.32:3000/cooperativas'));
      if (response.statusCode == 200) {
        final List<dynamic> serverData = jsonDecode(response.body);
        for (var coopData in serverData) {
          final coop = Cooperative.fromMap(coopData);
          await _dbHelper.insertCooperative(coop);
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error en syncWithServer: $e');
    }
  }
}
