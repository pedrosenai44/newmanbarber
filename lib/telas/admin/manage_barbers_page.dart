import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBarbersPage extends StatefulWidget {
  const ManageBarbersPage({super.key});

  @override
  State<ManageBarbersPage> createState() => _ManageBarbersPageState();
}

class _ManageBarbersPageState extends State<ManageBarbersPage> {
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Função para adicionar barbeiro no Firestore
  Future<void> _addBarber() async {
    if (_nameController.text.isEmpty || _specialtyController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('barbers').add({
      'name': _nameController.text.trim(),
      'specialty': _specialtyController.text.trim(),
      'imageUrl': _imageUrlController.text.trim().isNotEmpty 
          ? _imageUrlController.text.trim() 
          : 'https://images.unsplash.com/photo-1585747833871-693963cbeee9?auto=format&fit=crop&q=80&w=200', // Imagem padrão
      'rating': 5.0, // Começa com 5 estrelas
      'createdAt': FieldValue.serverTimestamp(),
    });

    _nameController.clear();
    _specialtyController.clear();
    _imageUrlController.clear();
    
    if (mounted) Navigator.of(context).pop(); // Fecha o modal
  }

  // Função para deletar barbeiro
  Future<void> _deleteBarber(String id) async {
    await FirebaseFirestore.instance.collection('barbers').doc(id).delete();
  }

  // Modal para preencher os dados
  void _showAddBarberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Barbeiro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _specialtyController,
              decoration: const InputDecoration(labelText: 'Especialidade (ex: Cortes Clássicos)'),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'URL da Foto (Opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: _addBarber, child: const Text('Salvar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Barbeiros'),
        backgroundColor: Colors.blue.shade300,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBarberDialog,
        backgroundColor: Colors.blue.shade300,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('barbers').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum barbeiro cadastrado.'));
          }

          final barbers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: barbers.length,
            itemBuilder: (context, index) {
              final barber = barbers[index];
              final data = barber.data() as Map<String, dynamic>;
              final id = barber.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(data['imageUrl'] ?? ''),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  title: Text(data['name'] ?? 'Sem Nome'),
                  subtitle: Text(data['specialty'] ?? 'Sem Especialidade'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteBarber(id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
