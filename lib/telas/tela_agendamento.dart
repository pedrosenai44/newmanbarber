import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'package:newmanbarber/telas/tela_principal.dart';
import 'package:newmanbarber/telas/agendamento_sucesso_page.dart';
import 'package:newmanbarber/utils/imagem_universal.dart';

class AppointmentPage extends StatefulWidget {
  final Servico servico;

  const AppointmentPage({super.key, required this.servico});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  int _passoAtual = 0;
  Map<String, dynamic>? _barbeiroSelecionado;
  DateTime? _dataSelecionada;
  String? _horarioSelecionado;
  bool _salvando = false;

  final List<String> _horarios = [
    '09:00', '09:30', '10:00', '10:30', '11:00',
    '13:00', '13:30', '14:00', '14:30', '15:00',
    '16:00', '16:30', '17:00', '17:30', '18:00',
  ];

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

  String _formatarDataSimples(DateTime data) {
    return "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";
  }

  Future<void> _confirmarAgendamento() async {
    setState(() {
      _salvando = true;
    });

    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) return;

      final dataSimples = _formatarDataSimples(_dataSelecionada!);

      await FirebaseFirestore.instance.collection('appointments').add({
        'userId': usuario.uid,
        'userName': usuario.displayName ?? 'Cliente',
        'userEmail': usuario.email,
        'serviceName': widget.servico.nome,
        'servicePrice': widget.servico.preco,
        'barberName': _barbeiroSelecionado!['nome'],
        'barberId': _barbeiroSelecionado!['id'], 
        'date': _dataSelecionada!.toIso8601String(), 
        'data_simples': dataSimples, 
        'time': _horarioSelecionado,
        'status': 'Confirmado',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
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

  Future<void> _abrirCalendario() async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: const Locale('pt', 'BR'), 
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (dataEscolhida != null) {
      setState(() {
        _dataSelecionada = dataEscolhida;
        _horarioSelecionado = null; 
      });
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

  bool _podeProsseguir() {
    if (_passoAtual == 0) return _barbeiroSelecionado != null;
    if (_passoAtual == 1) return _dataSelecionada != null;
    if (_passoAtual == 2) return _horarioSelecionado != null;
    return true;
  }

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

  Widget _selecaoBarbeiro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escolha o Profissional', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('barbeiros').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhum barbeiro disponível."));

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var dados = doc.data() as Map<String, dynamic>;
                  dados['id'] = doc.id;

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
                      onTap: () => setState(() => _barbeiroSelecionado = dados),
                      leading: ImagemUniversal(urlOuBase64: dados['foto'], width: 50, height: 50, radius: 25),
                      title: Text(dados['nome'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(dados['especialidade'] ?? 'Barbeiro Profissional'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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

  Widget _selecaoData() {
    String textoData = _dataSelecionada == null 
        ? "Toque para escolher" 
        : "${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year}";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text("Qual dia você prefere?", style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 20),
          InkWell(
            onTap: _abrirCalendario,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                textoData,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selecaoHorario() {
    if (_barbeiroSelecionado == null || _dataSelecionada == null) return const Center(child: Text("Selecione Barbeiro e Data primeiro"));

    final dataSimples = _formatarDataSimples(_dataSelecionada!);
    final barberId = _barbeiroSelecionado!['id']; // USANDO ID PARA BUSCA MAIS PRECISA

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Horários Disponíveis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(
               "${_dataSelecionada!.day}/${_dataSelecionada!.month}",
               style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            )
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          // BUSCA REFINADA: Usa ID do barbeiro e data_simples
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('barberId', isEqualTo: barberId) // Busca por ID
                .where('data_simples', isEqualTo: dataSimples)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              List<String> horariosOcupados = [];
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final dados = doc.data() as Map<String, dynamic>;
                  // Bloqueia se o status NÃO for cancelado
                  if (dados['status'] != 'Cancelado') {
                    horariosOcupados.add(dados['time'] as String);
                  }
                }
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 10, mainAxisSpacing: 10,
                ),
                itemCount: _horarios.length,
                itemBuilder: (context, index) {
                  final horario = _horarios[index];
                  final estaOcupado = horariosOcupados.contains(horario);
                  final selecionado = _horarioSelecionado == horario;

                  return GestureDetector(
                    // Se ocupado, bloqueia clique
                    onTap: estaOcupado ? null : () => setState(() => _horarioSelecionado = horario),
                    child: Container(
                      decoration: BoxDecoration(
                        color: estaOcupado ? Colors.grey.shade100 : (selecionado ? Colors.blue : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: estaOcupado ? Colors.grey.shade300 : (selecionado ? Colors.blue : Colors.grey.shade300),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        estaOcupado ? "Ocupado" : horario, // Feedback visual claro
                        style: TextStyle(
                          color: estaOcupado ? Colors.grey : (selecionado ? Colors.white : Colors.black87),
                          decoration: estaOcupado ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.bold,
                          fontSize: estaOcupado ? 12 : 14,
                        ),
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

  Widget _resumo() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.blue),
        const SizedBox(height: 20),
        const Text("Tudo pronto?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              _linhaResumo(Icons.person, 'Profissional', _barbeiroSelecionado?['nome']),
              _linhaResumo(Icons.calendar_today, 'Data', "${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year}"),
              _linhaResumo(Icons.access_time, 'Horário', _horarioSelecionado ?? ''),
              const Divider(height: 30),
              _linhaResumo(Icons.content_cut, 'Serviço', widget.servico.nome),
              _linhaResumo(Icons.attach_money, 'Valor', widget.servico.preco),
            ],
          ),
        ),
      ],
    );
  }

  Widget _linhaResumo(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _indicadorPasso(int passo, String rotulo) {
    final ativo = _passoAtual >= passo;
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: ativo ? Colors.blue.shade800 : Colors.blue.shade200,
          child: Text((passo + 1).toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(rotulo, style: TextStyle(color: ativo ? Colors.white : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _linha() {
    return Container(width: 20, height: 2, color: Colors.white54, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12));
  }
}
