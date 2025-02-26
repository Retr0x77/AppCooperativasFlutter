import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/cooperative_detail_screen.dart';
import '../auth_service.dart';
import '../cooperative_service.dart';
import '../database/database_helper.dart';

class JoinCooperativeScreen extends StatelessWidget {
  final String cooperativeId;

  const JoinCooperativeScreen({Key? key, required this.cooperativeId})
      : super(key: key);

  Future<void> _joinCooperative(BuildContext context) async {
    final cooperativeService =
        Provider.of<CooperativeService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final dbHelper = DatabaseHelper();

    // Obtener el usuario actual
    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    try {
      // Verificar si la cooperativa existe en SQLite
      final cooperative = await dbHelper.getCooperativeById(cooperativeId);
      if (cooperative == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cooperativa no encontrada')),
        );
        return;
      }

      // Verificar si el usuario ya es miembro
      final miembros = await dbHelper.getMiembros(cooperativeId);
      final isMember = miembros.any((m) => m.userId == user.id.toString());

      if (isMember) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya eres miembro de esta cooperativa')),
        );
        return;
      }

      // Unirse a la cooperativa
      await cooperativeService.joinCooperative(
          cooperativeId, user.id.toString());

      // Navegar a la pantalla de detalles de la cooperativa
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CooperativeDetailScreen(cooperativeId: cooperativeId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unirse a Cooperativa")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _joinCooperative(context),
          child: const Text("Unirse"),
        ),
      ),
    );
  }
}
