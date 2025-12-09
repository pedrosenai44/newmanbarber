import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newmanbarber/utils/imagem_universal.dart';

class GerenciarBarbeirosPage extends StatefulWidget {
  const GerenciarBarbeirosPage({super.key});

  @override
  State<GerenciarBarbeirosPage> createState() => _GerenciarBarbeirosPageState();
}

class _GerenciarBarbeirosPageState extends State<GerenciarBarbeirosPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController(); // CAMPO NOVO PARA EMAIL

  File? _imagemSelecionada;
  String? _stringImagemFinal;
  bool _enviando = false;

  Future<void> _escolherImagem(ImageSource origem, StateSetter setStateDialog) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: origem, imageQuality: 25, maxWidth: 400);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64String = base64Encode(bytes);
        setStateDialog(() {
          _imagemSelecionada = File(image.path);
          _stringImagemFinal = base64String;
        });
      }
    } catch (e) {
      // erro
    }
  }

  Future<void> _adicionarLink(StateSetter setStateDialog) async {
    final linkController = TextEditingController();
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Adicionar Link da Foto'),
              content: TextField(controller: linkController, decoration: const InputDecoration(labelText: 'URL da Foto')),
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
            ));
  }

  Future<void> _salvarBarbeiro(StateSetter setStateDialog, {String? docId}) async {
    if (_nomeController.text.isEmpty || _emailController.text.isEmpty) return;

    setStateDialog(() => _enviando = true);

    Map<String, dynamic> updateData = {
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim().toLowerCase(), // Salvar email em minúsculo
    };
    if (_stringImagemFinal != null) {
      updateData['foto'] = _stringImagemFinal!;
    }

    if (docId == null) {
      updateData['avaliacao'] = 5.0; // Padrão para novos
      await FirebaseFirestore.instance.collection('barbeiros').add(updateData);
    } else {
      await FirebaseFirestore.instance.collection('barbeiros').doc(docId).update(updateData);
    }

    _limparCampos();
    setStateDialog(() => _enviando = false);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deletarBarbeiro(String id) async {
    // A lógica de delete continua a mesma
    await FirebaseFirestore.instance.collection('barbeiros').doc(id).delete();
  }

  void _limparCampos() {
    _nomeController.clear();
    _emailController.clear();
    _imagemSelecionada = null;
    _stringImagemFinal = null;
  }

  void _mostrarDialogo({String? docId, Map<String, dynamic>? dadosAtuais}) {
    _limparCampos();

    if (docId != null && dadosAtuais != null) {
      _nomeController.text = dadosAtuais['nome'] ?? '';
      _emailController.text = dadosAtuais['email'] ?? '';
      _stringImagemFinal = dadosAtuais['foto'];
    }

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text(docId == null ? 'Novo Barbeiro' : 'Editar Barbeiro'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ImagemUniversal(
                            urlOuBase64: _stringImagemFinal,
                            arquivoLocal: _imagemSelecionada,
                            width: 100,
                            height: 100,
                            radius: 50,
                          ),
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                            onSelected: (opcao) {
                              if (opcao == 'camera') _escolherImagem(ImageSource.camera, setStateDialog);
                              if (opcao == 'galeria') _escolherImagem(ImageSource.gallery, setStateDialog);
                              if (opcao == 'link') _adicionarLink(setStateDialog);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'camera', child: ListTile(leading: Icon(Icons.camera_alt), title: Text('Câmera'))),
                              const PopupMenuItem(value: 'galeria', child: ListTile(leading: Icon(Icons.photo_library), title: Text('Galeria'))),
                              const PopupMenuItem(value: 'link', child: ListTile(leading: Icon(Icons.link), title: Text('Colar Link'))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome do Barbeiro', prefixIcon: Icon(Icons.person_outline))),
                      const SizedBox(height: 16),
                      // CAMPO DE EMAIL ADICIONADO
                      TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email de Login do Barbeiro', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
                      if (_enviando) ...[const SizedBox(height: 20), const CircularProgressIndicator(), const Text("Salvando...")]
                    ],
                  ),
                ),
                actions: [
                  if (!_enviando) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  if (!_enviando) ElevatedButton(onPressed: () => _salvarBarbeiro(setStateDialog, docId: docId), child: Text(docId == null ? 'Adicionar' : 'Salvar')),
                ],
              );
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Barbeiros'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: () => _mostrarDialogo(), backgroundColor: Colors.blue, child: const Icon(Icons.add, color: Colors.white)),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('barbeiros').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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
                  onTap: () => _mostrarDialogo(docId: doc.id, dadosAtuais: dados),
                  leading: ImagemUniversal(urlOuBase64: dados['foto'], width: 50, height: 50, radius: 25),
                  title: Text(dados['nome'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(dados['email'] ?? 'Email não definido'), // MOSTRA O EMAIL
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
