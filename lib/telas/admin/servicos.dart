import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newmanbarber/utils/imagem_universal.dart';

class GerenciarServicosPage extends StatefulWidget {
  const GerenciarServicosPage({super.key});

  @override
  State<GerenciarServicosPage> createState() => _GerenciarServicosPageState();
}

class _GerenciarServicosPageState extends State<GerenciarServicosPage> {
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _duracaoController = TextEditingController(); 
  
  File? _imagemSelecionada;
  String? _stringImagemFinal; 
  bool _enviando = false;

  String _categoriaSelecionada = 'Cortes';
  final List<String> _categorias = ['Cortes', 'Barba', 'Combos', 'Especial'];

  Future<void> _escolherImagem(ImageSource origem, StateSetter setStateDialog) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imagem = await picker.pickImage(source: origem, imageQuality: 25, maxWidth: 400);
      if (imagem != null) {
        final bytes = await File(imagem.path).readAsBytes();
        final base64String = base64Encode(bytes);
        setStateDialog(() {
          _imagemSelecionada = File(imagem.path);
          _stringImagemFinal = base64String;
        });
      }
    } catch (e) {
      print("Erro ao selecionar imagem: $e");
    }
  }

  Future<void> _adicionarLink(StateSetter setStateDialog) async {
    final linkController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar Link da Imagem'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(hintText: 'https://...', labelText: 'URL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (linkController.text.isNotEmpty) {
                setStateDialog(() {
                  _stringImagemFinal = linkController.text.trim();
                  _imagemSelecionada = null;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Função unificada SALVAR
  Future<void> _salvarServico(StateSetter setStateDialog, {String? docId}) async {
    if (_nomeController.text.isEmpty || _precoController.text.isEmpty) return;

    setStateDialog(() => _enviando = true);

    String precoFormatado = _precoController.text.startsWith('R\$') 
        ? _precoController.text 
        : 'R\$ ${_precoController.text}';

    Map<String, dynamic> dados = {
      'nome': _nomeController.text,
      'preco': precoFormatado,
      'duracao': _duracaoController.text.isEmpty ? '30 min' : _duracaoController.text,
      'categoria': _categoriaSelecionada,
    };
    
    if (_stringImagemFinal != null) {
      dados['urlImagem'] = _stringImagemFinal!;
    } else if (docId == null) {
      // Se for novo e não tiver imagem, usa padrão
      dados['urlImagem'] = 'https://cdn-icons-png.flaticon.com/512/2098/2098243.png';
    }

    if (docId == null) {
      await FirebaseFirestore.instance.collection('servicos').add(dados);
    } else {
      await FirebaseFirestore.instance.collection('servicos').doc(docId).update(dados);
    }

    _limparCampos();
    setStateDialog(() => _enviando = false);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deletarServico(String id) async {
    await FirebaseFirestore.instance.collection('servicos').doc(id).delete();
  }

  void _limparCampos() {
    _nomeController.clear();
    _precoController.clear();
    _duracaoController.clear();
    _imagemSelecionada = null;
    _stringImagemFinal = null;
    setState(() => _categoriaSelecionada = 'Cortes');
  }

  // Agora aceita parâmetros para edição
  void _mostrarDialogo({String? docId, Map<String, dynamic>? dadosAtuais}) {
    _limparCampos(); 

    if (docId != null && dadosAtuais != null) {
      _nomeController.text = dadosAtuais['nome'];
      // Remove R$ para edição
      _precoController.text = dadosAtuais['preco'].toString().replaceAll('R\$ ', ''); 
      _duracaoController.text = dadosAtuais['duracao'];
      _stringImagemFinal = dadosAtuais['urlImagem'];
      
      // Garante que a categoria existe na lista, senão usa padrão
      if (_categorias.contains(dadosAtuais['categoria'])) {
        _categoriaSelecionada = dadosAtuais['categoria'];
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(docId == null ? 'Novo Serviço' : 'Editar Serviço'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ImagemUniversal(
                          urlOuBase64: _stringImagemFinal,
                          arquivoLocal: _imagemSelecionada,
                          width: 120,
                          height: 120,
                          radius: 12, 
                        ),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                          onSelected: (opcao) {
                            if (opcao == 'camera') _escolherImagem(ImageSource.camera, setStateDialog);
                            if (opcao == 'galeria') _escolherImagem(ImageSource.gallery, setStateDialog);
                            if (opcao == 'link') _adicionarLink(setStateDialog);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'camera', child: ListTile(leading: Icon(Icons.camera_alt), title: Text('Tirar Foto'))),
                            const PopupMenuItem(value: 'galeria', child: ListTile(leading: Icon(Icons.photo_library), title: Text('Galeria'))),
                             const PopupMenuItem(value: 'link', child: ListTile(leading: Icon(Icons.link), title: Text('Colar Link'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome')),
                  TextField(controller: _precoController, decoration: const InputDecoration(labelText: 'Preço'), keyboardType: TextInputType.number),
                  TextField(controller: _duracaoController, decoration: const InputDecoration(labelText: 'Duração')),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _categoriaSelecionada,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setStateDialog(() => _categoriaSelecionada = val!),
                  ),
                  if (_enviando) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const Text("Salvando..."),
                  ]
                ],
              ),
            ),
            actions: [
              if (!_enviando) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              if (!_enviando) ElevatedButton(
                onPressed: () => _salvarServico(setStateDialog, docId: docId), 
                child: Text(docId == null ? 'Salvar' : 'Atualizar')
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
        onPressed: () => _mostrarDialogo(),
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
                onTap: () => _mostrarDialogo(docId: doc.id, dadosAtuais: dados), // CLIQUE PARA EDITAR
                leading: ImagemUniversal(
                  urlOuBase64: dados['urlImagem'],
                  width: 50,
                  height: 50,
                  radius: 8,
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
