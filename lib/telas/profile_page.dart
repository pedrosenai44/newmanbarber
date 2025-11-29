import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:newmanbarber/telas/login_page.dart';
import 'package:newmanbarber/telas/admin/manage_barbers_page.dart'; // Importar a página de admin

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Função para deslogar
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // Função para cancelar agendamento
  Future<void> _cancelAppointment(String appointmentId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'Cancelado',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento cancelado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cancelar agendamento.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Usuário não logado"));
    }

    // StreamBuilder to listen for real-time updates from Firestore (USER PROFILE)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Error state
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text("Erro ao carregar perfil")));
        }

        // Extract data from the document
        final userData = snapshot.data?.data() as Map<String, dynamic>?;

        // Fallback values if data is missing
        final String userName = userData?['name'] ?? user.displayName ?? 'Usuário';
        final String userEmail = userData?['email'] ?? user.email ?? 'Sem email';
        final String userPhone = userData?['phone'] ?? 'Telefone não cadastrado';
        // Verificar role diretamente do banco
        final bool isAdmin = userData?['role'] == 'admin';
        final String userRoleDisplay = isAdmin ? 'Administrador' : 'Cliente';

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
                // Card de Informações do Usuário
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
                        Text(
                          userName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(userRoleDisplay, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const Divider(height: 32),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: Text(userEmail),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(userPhone),
                        ),
                        
                        // BOTÃO DE ADMIN (Só aparece se for admin)
                        if (isAdmin) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ManageBarbersPage()),
                              );
                            },
                            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                            label: const Text('Gerenciar Barbeiros', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange, // Cor diferente para destacar
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.exit_to_app, color: Colors.white),
                          label: const Text('Sair da Conta', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- SEÇÃO DE AGENDAMENTOS (AGORA CONECTADA AO FIREBASE) ---
                const Text('Meus Agendamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                
                // StreamBuilder para ler agendamentos
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('userId', isEqualTo: user.uid) // Filtra pelo usuário atual
                      .orderBy('createdAt', descending: true) // Ordena do mais novo para o mais antigo
                      .snapshots(),
                  builder: (context, appointmentSnapshot) {
                    if (appointmentSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!appointmentSnapshot.hasData || appointmentSnapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    final appointments = appointmentSnapshot.data!.docs;

                    return Column(
                      children: appointments.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final appointmentId = doc.id;
                        return _buildAppointmentCard(data, appointmentId, context);
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

  // Widget para exibir cada agendamento
  Widget _buildAppointmentCard(Map<String, dynamic> data, String appointmentId, BuildContext context) {
    final String status = data['status'] ?? 'Confirmado';
    final bool isCancelled = status == 'Cancelado';
    
    // Formatar data (supondo que salvamos como string ISO ou timestamp)
    String formattedDate = data['date']?.toString().split('T')[0] ?? 'Data inválida'; // Simplificação
    
    // Tenta formatar melhor se possível, aqui pegamos a parte da data da string ISO
    if (data['date'] is String && data['date'].contains('T')) {
       final DateTime dateTime = DateTime.parse(data['date']);
       formattedDate = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16), // Espaço entre cards
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(data['serviceName'] ?? 'Serviço', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCancelled ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status, 
                    style: TextStyle(
                      color: isCancelled ? Colors.red : Colors.green, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.person_outline), 
              title: Text(data['barberName'] ?? 'Barbeiro'), 
              dense: true, 
              visualDensity: const VisualDensity(vertical: -4)
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined), 
              title: Text(formattedDate), 
              dense: true, 
              visualDensity: const VisualDensity(vertical: -4)
            ),
            ListTile(
              leading: const Icon(Icons.access_time_outlined), 
              title: Text(data['time'] ?? 'Horário'), 
              dense: true, 
              visualDensity: const VisualDensity(vertical: -4)
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['servicePrice'] ?? 'R\$ --', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                
                // Botão Cancelar (só aparece se não estiver cancelado)
                if (!isCancelled)
                  OutlinedButton(
                    onPressed: () => _cancelAppointment(appointmentId, context),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Cancelar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(Icons.history, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Você ainda não tem histórico de agendamentos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
