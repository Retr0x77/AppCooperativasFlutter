import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cooperative_service.dart';
import '../database/database_helper.dart';
import '../screens/create_cooperative_screen.dart';
import '../screens/cooperative_detail_screen.dart';

class CooperativesScreen extends StatefulWidget {
  @override
  _CooperativesScreenState createState() => _CooperativesScreenState();
}

class _CooperativesScreenState extends State<CooperativesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cooperativeService = Provider.of<CooperativeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cooperativas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                Navigator.pushNamed(context, '/create_cooperative'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar Cooperativa',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text;
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Cooperative>>(
              future: cooperativeService.getCooperativas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final cooperativas = snapshot.data ?? [];
                final filteredCooperativas = cooperativas
                    .where((coop) => coop.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredCooperativas.length,
                  itemBuilder: (context, index) {
                    final cooperative = filteredCooperativas[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          cooperative.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(cooperative.description),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CooperativeDetailScreen(
                                  cooperativeId: cooperative.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
