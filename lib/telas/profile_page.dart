import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:newmanbarber/telas/login_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Usuário não logado"));
    }

    // StreamBuilder to listen for real-time updates from Firestore
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
        final String userRole = userData?['role'] == 'admin' ? 'Administrador' : 'Cliente';

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
                        Text(userRole, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const Divider(height: 32),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: Text(userEmail),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(userPhone),
                        ),
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

                // --- SEÇÃO DE AGENDAMENTOS ---
                const Text('Meus Agendamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                
                // Aqui futuramente faremos outra consulta ao Firebase para os agendamentos
                _buildEmptyState(),
              ],
            ),
          ),
        );
      },
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
