import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newmanbarber/telas/tela_principal.dart'; // Para usar a classe Servico
import 'package:newmanbarber/telas/agendamento_sucesso_page.dart';

class AppointmentPage extends StatefulWidget {
  final Servico servico;

  const AppointmentPage({super.key, required this.servico});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // Estado
  int _passoAtual = 0;

  // Agora armazenamos os dados do barbeiro selecionado como um Map vindo do Firebase
  Map<String, dynamic>? _barbeiroSelecionado;

  DateTime? _dataSelecionada;
  String? _horarioSelecionado;
  bool _salvando = false;

  // Horários fixos (Você pode mover isso pro Firebase no futuro se quiser)
  final List<String> _horarios = [
    '09:00', '09:30', '10:00', '10:30', '11:00',
    '13:00', '13:30', '14:00', '14:30', '15:00',
    '16:00', '16:30', '17:00', '17:30', '18:00',
  ];

  // Navegação
  void _proximoPasso() {
    if (_passoAtual < 3) {
      setState(() {
        _passoAtual++;
      });
    } else {
      _confirmarAgendamento();
    }
  }

  void _passoAnterior() {
    if (_passoAtual > 0) {
      setState(() {
        _passoAtual--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  // Salvar no Firebase
  Future<void> _confirmarAgendamento() async {
    setState(() {
      _salvando = true;
    });

    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) return;

      await FirebaseFirestore.instance.collection('appointments').add({
        'userId': usuario.uid,
        'userName': usuario.displayName ?? 'Cliente',
        'userEmail': usuario.email,
        'serviceName': widget.servico.nome,
        'servicePrice': widget.servico.preco,
        'barberName': _barbeiroSelecionado!['nome'], // Pega do Map selecionado
        'date': _dataSelecionada!.toIso8601String(),
        'time': _horarioSelecionado,
        'status': 'Confirmado',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Navegar para a tela de sucesso
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AgendamentoSucessoPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao agendar: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _passoAnterior,
        ),
      ),
      body: _salvando
          ? const Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.white],
            stops: const [0.1, 0.6],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _indicadorPasso(0, 'Barbeiro'),
                  _linha(),
                  _indicadorPasso(1, 'Data'),
                  _linha(),
                  _indicadorPasso(2, 'Horário'),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: _conteudoPassoAtual(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _salvando ? null : Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _podeProsseguir() ? _proximoPasso : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade400,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: Text(
            _passoAtual == 3 ? 'Confirmar Agendamento' : 'Continuar',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Validação
  bool _podeProsseguir() {
    if (_passoAtual == 0) return _barbeiroSelecionado != null;
    if (_passoAtual == 1) return _dataSelecionada != null;
    if (_passoAtual == 2) return _horarioSelecionado != null;
    return true;
  }

  // Conteúdo Dinâmico
  Widget _conteudoPassoAtual() {
    switch (_passoAtual) {
      case 0:
        return _selecaoBarbeiro();
      case 1:
        return _selecaoData();
      case 2:
        return _selecaoHorario();
      case 3:
        return _resumo();
      default:
        return const SizedBox.shrink();
    }
  }

  // Passo 1: Seleção de Barbeiro (Agora com Firebase!)
  Widget _selecaoBarbeiro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escolha o Profissional', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Conecta na coleção 'barbeiros' que você criou no Admin
            stream: FirebaseFirestore.instance.collection('barbeiros').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Nenhum barbeiro disponível no momento."));
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  // Converte o documento para Map
                  var dados = doc.data() as Map<String, dynamic>;

                  // Adiciona o ID do documento aos dados caso precise
                  dados['id'] = doc.id;

                  String nome = dados['nome'] ?? 'Sem Nome';
                  String foto = dados['foto'] ?? '';
                  double avaliacao = (dados['avaliacao'] ?? 5.0).toDouble();

                  // Verifica se é o selecionado comparando o ID ou Nome
                  // Aqui comparamos o objeto Map inteiro por simplicidade
                  final selecionado = _barbeiroSelecionado != null && _barbeiroSelecionado!['id'] == doc.id;

                  return Card(
                    color: selecionado ? Colors.blue.shade50 : Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: selecionado ? BorderSide(color: Colors.blue.shade400, width: 2) : BorderSide.none,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _barbeiroSelecionado = dados;
                        });
                      },
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (foto.isNotEmpty) ? NetworkImage(foto) : null,
                        child: (foto.isEmpty) ? const Icon(Icons.person, color: Colors.grey) : null,
                      ),
                      title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      // Se não tiver especialidade cadastrada, mostra um texto padrão
                      subtitle: Text(dados['especialidade'] ?? 'Barbeiro Profissional'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(avaliacao.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Passo 2: Data
  Widget _selecaoData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escolha a Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue.shade400,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              onDateChanged: (data) => setState(() => _dataSelecionada = data),
            ),
          ),
        ),
      ],
    );
  }

  // Passo 3: Horário
  Widget _selecaoHorario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escolha o Horário', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _horarios.length,
            itemBuilder: (context, index) {
              final horario = _horarios[index];
              final selecionado = _horarioSelecionado == horario;
              return ChoiceChip(
                label: Text(horario),
                selected: selecionado,
                onSelected: (bool sel) => setState(() => _horarioSelecionado = sel ? horario : null),
                selectedColor: Colors.blue.shade400,
                labelStyle: TextStyle(color: selecionado ? Colors.white : Colors.black),
              );
            },
          ),
        ),
      ],
    );
  }

  // Passo 4: Resumo
  Widget _resumo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumo do Agendamento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _linhaResumo(Icons.content_cut, 'Serviço', widget.servico.nome),
        _linhaResumo(Icons.attach_money, 'Valor', widget.servico.preco),
        const Divider(),
        // Pega o nome do Map selecionado
        _linhaResumo(Icons.person, 'Barbeiro', _barbeiroSelecionado?['nome'] ?? 'Não selecionado'),
        _linhaResumo(Icons.calendar_today, 'Data', _dataSelecionada?.toLocal().toString().split(' ')[0] ?? ''),
        _linhaResumo(Icons.access_time, 'Horário', _horarioSelecionado ?? ''),
      ],
    );
  }

  Widget _linhaResumo(IconData icone, String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icone, color: Colors.blue.shade400),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  // Visual
  Widget _indicadorPasso(int passo, String rotulo) {
    final ativo = _passoAtual >= passo;
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: ativo ? Colors.blue.shade800 : Colors.blue.shade200,
          child: Text((passo + 1).toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(rotulo, style: TextStyle(color: ativo ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _linha() {
    return Container(width: 30, height: 2, color: Colors.white54, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15));
  }
}
