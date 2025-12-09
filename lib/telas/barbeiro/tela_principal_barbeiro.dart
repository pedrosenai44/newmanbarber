import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newmanbarber/telas/tela_login.dart';

class BarberHomePage extends StatefulWidget {
  const BarberHomePage({super.key});

  @override
  State<BarberHomePage> createState() => _BarberHomePageState();
}

class _BarberHomePageState extends State<BarberHomePage> {
  String? _barberId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarberId();
  }

  // Função que descobre o ID do Barbeiro usando o email
  Future<void> _loadBarberId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('barbeiros')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _barberId = query.docs.first.id;
          _isLoading = false;
        });
      } else {
        // Não encontrou um perfil de barbeiro para este email
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // Lidar com erro, talvez mostrar um SnackBar
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
            tooltip: 'Sair',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostra carregando enquanto busca o ID
          : _barberId == null
              ? const Center(child: Text('Não foi possível encontrar seu perfil de barbeiro.')) // Erro se não achar
              : _buildAgenda(), // Constrói a agenda se achar o ID
    );
  }

  Widget _buildAgenda() {
     final user = FirebaseAuth.instance.currentUser;
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Bem-vindo, ${user?.displayName ?? 'Barbeiro'}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Seus próximos agendamentos:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // AGORA A BUSCA É PELO ID CORRETO E SEGURO
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('barberId', isEqualTo: _barberId)
                  .where('status', isEqualTo: 'Confirmado')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Você não tem agendamentos confirmados para os próximos dias.', textAlign: TextAlign.center),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var dados = doc.data() as Map<String, dynamic>;

                    String dataFormatada = 'Data não informada';
                     if (dados.containsKey('date')) {
                      try {
                        final DateTime dataObj = DateTime.parse(dados['date']);
                        dataFormatada = "${dataObj.day}/${dataObj.month}/${dataObj.year}";
                      } catch (e) { /* ignora */ }
                    }

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(dados['time'] ?? '--:--', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        title: Text(dados['serviceName'] ?? 'Serviço', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Cliente: ${dados['userName'] ?? 'Não informado'} em $dataFormatada'),
                        trailing: const Icon(Icons.check_circle_outline, color: Colors.green),
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
}
