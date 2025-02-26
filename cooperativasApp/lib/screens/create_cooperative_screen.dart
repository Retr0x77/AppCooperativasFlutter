//archivo create_cooperatives_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cooperative_service.dart';

class CreateCooperativeScreen extends StatelessWidget {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _createCooperative(BuildContext context) {
    final cooperativeService =
        Provider.of<CooperativeService>(context, listen: false);
    cooperativeService.createCooperative(
      _nameController.text,
      _descriptionController.text,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crear Cooperativa")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Descripción"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _createCooperative(context),
              child: Text("Crear"),
            ),
          ],
        ),
      ),
    );
  }
}
