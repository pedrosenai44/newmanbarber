import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newmanbarber/telas/admin/barbeiros.dart';
import 'package:newmanbarber/telas/tela_login.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _sair(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _cancelarAgendamento(String idAgendamento, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(idAgendamento).update({
        'status': 'Cancelado',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento cancelado.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao cancelar.')));
      }
    }
  }

  // EXCLUIR HISTÓRICO COM FEEDBACK DE ERRO
  Future<void> _excluirHistorico(String idAgendamento, BuildContext context) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Histórico?"),
        content: const Text("Este registro será apagado permanentemente."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Manter"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmar) {
      try {
        await FirebaseFirestore.instance.collection('appointments').doc(idAgendamento).delete();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Erro ao excluir: ${e.toString()}'), 
               backgroundColor: Colors.red
             )
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Center(child: Text("Usuário não logado"));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(usuario.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final dadosUsuario = snapshot.data?.data() as Map<String, dynamic>?;
        final String nome = dadosUsuario?['name'] ?? usuario.displayName ?? 'Usuário';
        final String email = dadosUsuario?['email'] ?? usuario.email ?? 'Sem email';
        final String telefone = dadosUsuario?['phone'] ?? 'Telefone não cadastrado';
        final bool ehAdmin = dadosUsuario?['role'] == 'admin';
        final String papelDisplay = ehAdmin ? 'Administrador' : 'Cliente';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: Colors.black87),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade300, Colors.white],
                stops: const [0.1, 0.7],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(papelDisplay, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const Divider(height: 32),
                        ListTile(leading: const Icon(Icons.email_outlined), title: Text(email)),
                        ListTile(leading: const Icon(Icons.phone_outlined), title: Text(telefone)),
                        
                        if (ehAdmin) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const GerenciarBarbeirosPage()));
                            },
                            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                            label: const Text('Gerenciar Barbeiros', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ],

                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _sair(context),
                          icon: const Icon(Icons.exit_to_app, color: Colors.white),
                          label: const Text('Sair da Conta', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Meus Agendamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('userId', isEqualTo: usuario.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapAgendamentos) {
                    if (snapAgendamentos.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapAgendamentos.hasData || snapAgendamentos.data!.docs.isEmpty) {
                      return _construirEstadoVazio();
                    }

                    final agendamentos = snapAgendamentos.data!.docs;

                    return Column(
                      children: agendamentos.map((doc) {
                        final dados = doc.data() as Map<String, dynamic>;
                        final idAgendamento = doc.id;
                        return _construirCardAgendamento(dados, idAgendamento, context);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirCardAgendamento(Map<String, dynamic> dados, String idAgendamento, BuildContext context) {
    final String status = dados['status'] ?? 'Confirmado';
    final bool cancelado = status == 'Cancelado';
    
    String dataFormatada = dados['date']?.toString().split('T')[0] ?? 'Data inválida';
    if (dados['date'] is String && dados['date'].contains('T')) {
       final DateTime dataObj = DateTime.parse(dados['date']);
       dataFormatada = "${dataObj.day}/${dataObj.month}/${dataObj.year}";
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(dados['serviceName'] ?? 'Serviço', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (cancelado) 
                   IconButton(
                     icon: const Icon(Icons.delete_outline, color: Colors.grey),
                     onPressed: () => _excluirHistorico(idAgendamento, context),
                     tooltip: "Apagar do histórico",
                   )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status, 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            ListTile(leading: const Icon(Icons.person_outline), title: Text(dados['barberName'] ?? 'Barbeiro'), dense: true, visualDensity: const VisualDensity(vertical: -4)),
            ListTile(leading: const Icon(Icons.calendar_today_outlined), title: Text(dataFormatada), dense: true, visualDensity: const VisualDensity(vertical: -4)),
            ListTile(leading: const Icon(Icons.access_time_outlined), title: Text(dados['time'] ?? 'Horário'), dense: true, visualDensity: const VisualDensity(vertical: -4)),
            
            if (cancelado) ...[
               const SizedBox(height: 8),
               const Text("Status: Cancelado", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dados['servicePrice'] ?? 'R\$ --', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                
                if (!cancelado)
                  OutlinedButton(
                    onPressed: () => _cancelarAgendamento(idAgendamento, context),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Cancelar Agendamento'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirEstadoVazio() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(Icons.history, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Você ainda não tem histórico de agendamentos.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
