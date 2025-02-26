import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../cooperative_service.dart';
import '../database/database_helper.dart';

class CooperativeDetailScreen extends StatelessWidget {
  final String cooperativeId;

  const CooperativeDetailScreen({Key? key, required this.cooperativeId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final cooperativeService = Provider.of<CooperativeService>(context);
    final dbHelper = DatabaseHelper();

    final userId = authService.currentUser?.id.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Cooperative?>(
          future: dbHelper.getCooperativeById(cooperativeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando...');
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Text('Cooperativa no encontrada');
            }

            return Text(snapshot.data!.name);
          },
        ),
      ),
      body: FutureBuilder<Cooperative?>(
        future: dbHelper.getCooperativeById(cooperativeId),
        builder: (context, coopSnapshot) {
          if (coopSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!coopSnapshot.hasData || coopSnapshot.data == null) {
            return const Center(child: Text('Cooperativa no encontrada'));
          }

          final cooperative = coopSnapshot.data!;

          return FutureBuilder<List<Member>>(
            future: dbHelper.getMiembros(cooperativeId),
            builder: (context, membersSnapshot) {
              if (membersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final miembros = membersSnapshot.data ?? [];
              final isMember = miembros.any((m) => m.userId == userId);
              final userBalance = miembros
                  .firstWhere(
                    (m) => m.userId == userId,
                    orElse: () => Member(userId: userId, balance: 0),
                  )
                  .balance;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cooperative.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Miembros:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: miembros.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(miembros[index].userId),
                          );
                        },
                      ),
                    ),
                    Text("Tu saldo: \$${userBalance.toStringAsFixed(2)}"),
                    const SizedBox(height: 20),
                    isMember
                        ? ElevatedButton(
                            onPressed: () async {
                              await cooperativeService.leaveCooperative(
                                  cooperativeId, userId);
                              // Forzar la reconstrucción de la pantalla
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CooperativeDetailScreen(
                                      cooperativeId: cooperativeId),
                                ),
                              );
                            },
                            child: const Text("Abandonar Cooperativa"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () => cooperativeService.joinCooperative(
                                cooperativeId, userId),
                            child: const Text("Unirse a la Cooperativa"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
