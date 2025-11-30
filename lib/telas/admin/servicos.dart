import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class GerenciarServicosPage extends StatefulWidget {
  const GerenciarServicosPage({super.key});

  @override
  State<GerenciarServicosPage> createState() => _GerenciarServicosPageState();
}

class _GerenciarServicosPageState extends State<GerenciarServicosPage> {
  // Controladores
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _duracaoController = TextEditingController(); 
  
  // Controle de Imagem
  File? _imagemSelecionada;
  String? _urlImagemExterna; // Para quando o usuário colar um link
  bool _enviando = false;

  // Categoria padrão
  String _categoriaSelecionada = 'Cortes';
  final List<String> _categorias = ['Cortes', 'Barba', 'Combos', 'Especial'];

  // Escolher Imagem da Galeria/Câmera
  Future<void> _escolherImagem(ImageSource origem, StateSetter setStateDialog) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imagem = await picker.pickImage(source: origem, imageQuality: 50);
      if (imagem != null) {
        setStateDialog(() {
          _imagemSelecionada = File(imagem.path);
          _urlImagemExterna = null; // Limpa o link se escolher arquivo
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
        title: const Text('Adicionar Link da Imagem'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(
            hintText: 'https://exemplo.com/foto.jpg',
            labelText: 'URL da Imagem',
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
                  _imagemSelecionada = null; // Limpa o arquivo se escolher link
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

  // Obter URL final (Upload ou Link)
  Future<String> _obterUrlImagem() async {
    // 1. Se tiver arquivo, faz upload
    if (_imagemSelecionada != null) {
       try {
        String nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = FirebaseStorage.instance.ref().child('servicos/$nomeArquivo.jpg');
        UploadTask task = ref.putFile(_imagemSelecionada!);
        TaskSnapshot snapshot = await task;
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        print("Erro upload: $e");
        return ''; // Falha no upload
      }
    } 
    // 2. Se tiver link externo, usa ele
    else if (_urlImagemExterna != null && _urlImagemExterna!.isNotEmpty) {
      return _urlImagemExterna!;
    }
    
    // 3. Se não tiver nada, retorna padrão
    return 'https://cdn-icons-png.flaticon.com/512/2098/2098243.png';
  }

  Future<void> _adicionarServico(StateSetter setStateDialog) async {
    if (_nomeController.text.isEmpty || _precoController.text.isEmpty) return;

    setStateDialog(() {
      _enviando = true;
    });

    String urlFinal = await _obterUrlImagem();
    if (urlFinal.isEmpty) urlFinal = 'https://cdn-icons-png.flaticon.com/512/2098/2098243.png';

    await FirebaseFirestore.instance.collection('servicos').add({
      'nome': _nomeController.text,
      'preco': 'R\$ ${_precoController.text}',
      'duracao': _duracaoController.text.isEmpty ? '30 min' : _duracaoController.text,
      'urlImagem': urlFinal,
      'categoria': _categoriaSelecionada,
    });

    _limparCampos();
    setStateDialog(() {
      _enviando = false;
    });

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
    _urlImagemExterna = null;
    setState(() {
      _categoriaSelecionada = 'Cortes';
    });
  }

  void _mostrarDialogoAdicionar() {
    _limparCampos(); 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          // Lógica para decidir qual imagem mostrar no preview
          ImageProvider? imageProvider;
          if (_imagemSelecionada != null) {
            imageProvider = FileImage(_imagemSelecionada!);
          } else if (_urlImagemExterna != null && _urlImagemExterna!.isNotEmpty) {
            imageProvider = NetworkImage(_urlImagemExterna!);
          }

          return AlertDialog(
            title: const Text('Novo Serviço'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            image: imageProvider != null
                              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                              : null,
                          ),
                          child: imageProvider == null 
                            ? const Icon(Icons.image, size: 50, color: Colors.grey) 
                            : null,
                        ),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
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
                  ),
                  const SizedBox(height: 8),
                  const Text("Toque no ícone para alterar a imagem", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
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
                  if (_enviando) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const Text("Salvando serviço..."),
                  ]
                ],
              ),
            ),
            actions: [
              if (!_enviando)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              if (!_enviando)
                ElevatedButton(
                  onPressed: () => _adicionarServico(setStateDialog),
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
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    dados['urlImagem'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.cut),
                  ),
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
