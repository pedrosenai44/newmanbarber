import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class GerenciarBarbeirosPage extends StatefulWidget {
  const GerenciarBarbeirosPage({super.key});

  @override
  State<GerenciarBarbeirosPage> createState() => _GerenciarBarbeirosPageState();
}

class _GerenciarBarbeirosPageState extends State<GerenciarBarbeirosPage> {
  final TextEditingController _nomeController = TextEditingController();
  
  // Controle de Imagem
  File? _imagemSelecionada;
  String? _urlImagemExterna;
  bool _enviando = false;

  Future<void> _escolherImagem(ImageSource origem, StateSetter setStateDialog) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imagem = await picker.pickImage(source: origem, imageQuality: 50);
      if (imagem != null) {
        setStateDialog(() {
          _imagemSelecionada = File(imagem.path);
          _urlImagemExterna = null;
        });
      }
    } catch (e) {
      print("Erro ao selecionar imagem: $e");
    }
  }

  // Adicionar Link Manualmente
  Future<void> _adicionarLink(StateSetter setStateDialog) async {
    final linkController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar Link da Foto'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(
            hintText: 'https://exemplo.com/foto.jpg',
            labelText: 'URL da Foto',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (linkController.text.isNotEmpty) {
                setStateDialog(() {
                  _urlImagemExterna = linkController.text.trim();
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

  // Upload para o Storage
  Future<String> _obterUrlImagem() async {
    if (_imagemSelecionada != null) {
       try {
        String nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = FirebaseStorage.instance.ref().child('barbeiros/$nomeArquivo.jpg');
        UploadTask task = ref.putFile(_imagemSelecionada!);
        TaskSnapshot snapshot = await task;
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        print("Erro upload: $e");
        return '';
      }
    } 
    else if (_urlImagemExterna != null && _urlImagemExterna!.isNotEmpty) {
      return _urlImagemExterna!;
    }
    return '';
  }

  Future<void> _adicionarBarbeiro(StateSetter setStateDialog) async {
    if (_nomeController.text.isEmpty) return;

    setStateDialog(() {
      _enviando = true;
    });

    String urlFoto = await _obterUrlImagem();

    await FirebaseFirestore.instance.collection('barbeiros').add({
      'nome': _nomeController.text.trim(),
      'foto': urlFoto, 
      'avaliacao': 5.0,
    });

    _nomeController.clear();
    _imagemSelecionada = null;
    _urlImagemExterna = null;
    
    setStateDialog(() {
      _enviando = false;
    });

    if (mounted) Navigator.of(context).pop(); 
  }

  Future<void> _deletarBarbeiro(String id) async {
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

  void _mostrarDialogoAdicionar() {
    _imagemSelecionada = null; 
    _urlImagemExterna = null;
    _nomeController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          ImageProvider? imageProvider;
          if (_imagemSelecionada != null) {
            imageProvider = FileImage(_imagemSelecionada!);
          } else if (_urlImagemExterna != null && _urlImagemExterna!.isNotEmpty) {
            imageProvider = NetworkImage(_urlImagemExterna!);
          }

          return AlertDialog(
            title: const Text('Novo Barbeiro'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: imageProvider,
                          child: imageProvider == null 
                            ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                            : null,
                        ),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                          onSelected: (opcao) {
                            if (opcao == 'camera') _escolherImagem(ImageSource.camera, setStateDialog);
                            if (opcao == 'galeria') _escolherImagem(ImageSource.gallery, setStateDialog);
                            if (opcao == 'link') _adicionarLink(setStateDialog);
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'camera',
                              child: ListTile(leading: Icon(Icons.camera_alt), title: Text('Tirar Foto'), contentPadding: EdgeInsets.zero),
                            ),
                            const PopupMenuItem<String>(
                              value: 'galeria',
                              child: ListTile(leading: Icon(Icons.photo_library), title: Text('Galeria'), contentPadding: EdgeInsets.zero),
                            ),
                            const PopupMenuItem<String>(
                              value: 'link',
                              child: ListTile(leading: Icon(Icons.link), title: Text('Colar Link'), contentPadding: EdgeInsets.zero),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Barbeiro',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_enviando) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  const Text("Enviando imagem..."),
                ]
              ],
            ),
            actions: [
              if (!_enviando)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              if (!_enviando)
                ElevatedButton(
                  onPressed: () => _adicionarBarbeiro(setStateDialog),
                  child: const Text('Adicionar'),
                ),
            ],
          );
        }
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
                      Text((dados['avaliacao'] ?? 5.0).toString()),
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
