import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GerenciarBarbeirosPage extends StatefulWidget {
  const GerenciarBarbeirosPage({super.key});

  @override
  State<GerenciarBarbeirosPage> createState() => _GerenciarBarbeirosPageState();
}

class _GerenciarBarbeirosPageState extends State<GerenciarBarbeirosPage> {
  // Controladores de texto
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _fotoUrlController = TextEditingController();

  // Função para Adicionar Barbeiro ao Firebase
  Future<void> _adicionarBarbeiro() async {
    if (_nomeController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('barbeiros').add({
      'nome': _nomeController.text.trim(),
      'foto': _fotoUrlController.text.trim(), // Se deixar vazio, tratamos na exibição
      'avaliacao': 5.0, // Começa com 5 estrelas por padrão
    });

    _nomeController.clear();
    _fotoUrlController.clear();
    if (mounted) Navigator.of(context).pop(); // Fecha o diálogo
  }

  // Função para Deletar Barbeiro
  Future<void> _deletarBarbeiro(String id) async {
    // Pergunta antes de deletar para evitar acidentes
    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tem certeza?'),
        content: const Text('Isso removerá o barbeiro da lista de agendamentos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmar) {
      await FirebaseFirestore.instance.collection('barbeiros').doc(id).delete();
    }
  }

  // Janela flutuante para digitar os dados
  void _mostrarDialogoAdicionar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Barbeiro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Barbeiro',
                icon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fotoUrlController,
              decoration: const InputDecoration(
                labelText: 'URL da Foto (Opcional)',
                hintText: 'https://exemplo.com/foto.jpg',
                icon: Icon(Icons.image),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _adicionarBarbeiro,
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Barbeiros'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAdicionar,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // StreamBuilder escuta o banco de dados em tempo real
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('barbeiros').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    'Nenhum barbeiro cadastrado',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var dados = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  // Mostra a foto se tiver URL, senão mostra um ícone padrão
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: (dados['foto'] != null && dados['foto'] != '')
                        ? NetworkImage(dados['foto'])
                        : null,
                    child: (dados['foto'] == null || dados['foto'] == '')
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    dados['nome'] ?? 'Sem Nome',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(dados['avaliacao'].toString()),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deletarBarbeiro(doc.id),
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
