import 'package:flutter/material.dart';
import 'package:newmanbarber/telas/login_page.dart';

class ProfilePage extends StatelessWidget {
  // Parameters to receive user data in the future
  final String userName;
  final String userEmail;
  final String userPhone;

  const ProfilePage({
    super.key,
    this.userName = 'João Silva',
    this.userEmail = 'pedro@gmail.com', // Now uses the parameter
    this.userPhone = '(11) 98765-4321',
  });

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // User Info Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const CircleAvatar(radius: 40, backgroundColor: Colors.blue, child: Icon(Icons.person, size: 50, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('Cliente', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const Divider(height: 32),
                    ListTile(leading: const Icon(Icons.email_outlined), title: Text(userEmail)),
                    ListTile(leading: const Icon(Icons.phone_outlined), title: Text(userPhone)),
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

            // --- APPOINTMENTS SECTION ---
            const Text('Próximos Agendamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            _buildAppointmentCard(),
            // To show the empty state, just replace _buildAppointmentCard() with _buildEmptyState()
            // _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  // Widget for displaying a scheduled appointment
  Widget _buildAppointmentCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Corte Masculino', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Confirmado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            const ListTile(leading: Icon(Icons.person_outline), title: Text('Thiago Costa'), dense: true, visualDensity: VisualDensity(vertical: -4)),
            const ListTile(leading: Icon(Icons.calendar_today_outlined), title: Text('10/11/2025'), dense: true, visualDensity: VisualDensity(vertical: -4)),
            const ListTile(leading: Icon(Icons.access_time_outlined), title: Text('09:00'), dense: true, visualDensity: VisualDensity(vertical: -4)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('R\$ 35', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                OutlinedButton(
                  onPressed: () {},
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

  // Widget for displaying the empty state (no appointments)
  Widget _buildEmptyState() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Você ainda não tem agendamentos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
