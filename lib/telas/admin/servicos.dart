import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GerenciarServicosPage extends StatefulWidget {
  const GerenciarServicosPage({super.key});

  @override
  State<GerenciarServicosPage> createState() => _GerenciarServicosPageState();
}

class _GerenciarServicosPageState extends State<GerenciarServicosPage> {
  // Controladores
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _duracaoController = TextEditingController(); // Novo
  final _imagemController = TextEditingController(); // Novo

  // Categoria padrão
  String _categoriaSelecionada = 'Cortes';
  final List<String> _categorias = ['Cortes', 'Barba', 'Combos', 'Especial'];

  Future<void> _adicionarServico() async {
    if (_nomeController.text.isEmpty || _precoController.text.isEmpty) return;

    // URL padrão caso o admin não coloque imagem
    String urlFinal = _imagemController.text.trim();
    if (urlFinal.isEmpty) {
      urlFinal = 'https://cdn-icons-png.flaticon.com/512/2098/2098243.png'; // Ícone de tesoura genérico
    }

    // Salva na coleção 'servicos' (Português, para padronizar)
    await FirebaseFirestore.instance.collection('servicos').add({
      'nome': _nomeController.text,
      'preco': 'R\$ ${_precoController.text}', // Salva já com o R$ para facilitar
      'duracao': _duracaoController.text.isEmpty ? '30 min' : _duracaoController.text,
      'urlImagem': urlFinal,
      'categoria': _categoriaSelecionada,
    });

    _limparCampos();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deletarServico(String id) async {
    await FirebaseFirestore.instance.collection('servicos').doc(id).delete();
  }

  void _limparCampos() {
    _nomeController.clear();
    _precoController.clear();
    _duracaoController.clear();
    _imagemController.clear();
    setState(() {
      _categoriaSelecionada = 'Cortes';
    });
  }

  void _mostrarDialogoAdicionar() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Necessário para o Dropdown funcionar no Dialog
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Novo Serviço Completo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome (ex: Corte Degradê)'),
                  ),
                  TextField(
                    controller: _precoController,
                    decoration: const InputDecoration(labelText: 'Preço (ex: 35,00)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _duracaoController,
                    decoration: const InputDecoration(labelText: 'Duração (ex: 45 min)'),
                  ),
                  TextField(
                    controller: _imagemController,
                    decoration: const InputDecoration(
                      labelText: 'Link da Imagem (Opcional)',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _categoriaSelecionada,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: _categorias.map((String cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() => _categoriaSelecionada = val!);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _adicionarServico,
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Serviços')),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAdicionar,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('servicos').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var dados = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: Image.network(
                  dados['urlImagem'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.cut),
                ),
                title: Text(dados['nome']),
                subtitle: Text("${dados['categoria']} - ${dados['preco']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletarServico(doc.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
