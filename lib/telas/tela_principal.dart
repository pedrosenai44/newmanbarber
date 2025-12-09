import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newmanbarber/telas/tela_agendamento.dart';
import 'package:newmanbarber/telas/tela_login.dart';
import 'package:newmanbarber/telas/tela_perfil.dart';
import 'package:newmanbarber/utils/imagem_universal.dart';
import 'package:newmanbarber/utils/verificar_email_lembrete.dart'; // Importa o lembrete

class Servico {
  final String id;
  final String nome;
  final String duracao;
  final String preco;
  final String urlImagem;
  final String categoria;

  Servico({
    required this.id,
    required this.nome,
    required this.duracao,
    required this.preco,
    required this.urlImagem,
    required this.categoria,
  });

  factory Servico.fromMap(Map<String, dynamic> map, String documentId) {
    return Servico(
      id: documentId,
      nome: map['nome'] ?? 'Sem Nome',
      duracao: map['duracao'] ?? '30 min',
      preco: map['preco']?.toString() ?? 'R\$ 0,00',
      urlImagem: (map['urlImagem'] != null && map['urlImagem'] != '')
          ? map['urlImagem']
          : 'https://cdn-icons-png.flaticon.com/512/2098/2098243.png',
      categoria: map['categoria'] ?? 'Outros',
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controladorBusca = TextEditingController();
  String _filtroSelecionado = 'Todos';
  String _textoBusca = '';

  @override
  void initState() {
    super.initState();
    _controladorBusca.addListener(() {
      setState(() {
        _textoBusca = _controladorBusca.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }

  void _aoSelecionarMenu(String resultado, BuildContext context) {
    if (resultado == 'sair') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else if (resultado == 'perfil') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itensMenu = <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(value: 'perfil', child: ListTile(leading: Icon(Icons.person), title: Text('Ver Perfil'))),
      const PopupMenuItem<String>(value: 'sair', child: ListTile(leading: Icon(Icons.exit_to_app), title: Text('Sair'))),
    ];

    return Scaffold(
      backgroundColor: Colors.blue.shade300,
      body: Column(
        children: [
          // WIDGET DE VERIFICAÇÃO DE EMAIL
          const VerificarEmailLembrete(),
          
          // AppBar customizada como parte do corpo
          _buildCustomAppBar(context, itensMenu),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade300, Colors.white],
                  stops: const [0.0, 0.7],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  BotoesFiltro(
                    filtroSelecionado: _filtroSelecionado,
                    aoSelecionar: (filtro) => setState(() => _filtroSelecionado = filtro),
                  ),
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('servicos').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('Nenhum serviço cadastrado ainda.', style: TextStyle(color: Colors.grey)),
                          );
                        }

                        final todosServicos = snapshot.data!.docs.map((doc) {
                          return Servico.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                        }).toList();

                        final servicosFiltrados = todosServicos.where((servico) {
                          final categoriaOk = _filtroSelecionado == 'Todos' || servico.categoria == _filtroSelecionado;
                          final buscaOk = servico.nome.toLowerCase().contains(_textoBusca);
                          return categoriaOk && buscaOk;
                        }).toList();

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: servicosFiltrados.length,
                          itemBuilder: (context, index) {
                            return CardServico(servico: servicosFiltrados[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // AppBar extraída para um método
  Widget _buildCustomAppBar(BuildContext context, List<PopupMenuEntry<String>> itensMenu) {
    return Material(
      color: Colors.blue.shade300,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              const Text('NewManBarber', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'serif', color: Colors.white, fontSize: 24)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  controller: _controladorBusca,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar serviços...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: PopupMenuButton<String>(
                      onSelected: (res) => _aoSelecionarMenu(res, context),
                      itemBuilder: (context) => itensMenu,
                      child: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.grey)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BotoesFiltro extends StatelessWidget {
  final String filtroSelecionado;
  final Function(String) aoSelecionar;

  const BotoesFiltro({super.key, required this.filtroSelecionado, required this.aoSelecionar});

  @override
  Widget build(BuildContext context) {
    final List<String> filtros = ['Todos', 'Cortes', 'Barba', 'Combos', 'Especial'];
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 16 : 8, right: index == filtros.length - 1 ? 16 : 0),
            child: ChoiceChip(
              label: Text(filtro),
              selected: filtroSelecionado == filtro,
              onSelected: (bool selecionado) {
                if (selecionado) {
                  aoSelecionar(filtro);
                }
              },
              backgroundColor: Colors.white.withOpacity(0.7),
              selectedColor: Colors.white,
              labelStyle: TextStyle(color: filtroSelecionado == filtro ? Colors.black : Colors.black54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }
}

class CardServico extends StatelessWidget {
  final Servico servico;

  const CardServico({super.key, required this.servico});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImagemUniversal(
            urlOuBase64: servico.urlImagem,
            width: double.infinity,
            height: 150,
            fit: BoxFit.cover,
            radius: 16, 
          ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.content_cut, color: Colors.grey, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(servico.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(servico.duracao, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentPage(servico: servico),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(servico.preco),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
