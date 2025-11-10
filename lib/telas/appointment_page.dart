import 'package:flutter/material.dart';
import 'package:newmanbarber/telas/home_page.dart';

// --- Data Models ---
class Barber {
  final String name;
  final String specialty;
  final double rating;
  final String imageUrl;

  Barber({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.imageUrl,
  });
}

class AppointmentPage extends StatefulWidget {
  final Service service;

  const AppointmentPage({super.key, required this.service});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // --- State Variables ---

  final List<Barber> _barbers = [
    Barber(name: 'Carlos Silva', specialty: 'Cortes Clássicos', rating: 4.9, imageUrl: 'https://images.unsplash.com/photo-1595152772105-20504a6a69a9?q=80&w=1887'),
    Barber(name: 'Rafael Santos', specialty: 'Fade e Degradê', rating: 4.8, imageUrl: 'https://images.unsplash.com/photo-1532710093739-947053e4148e?q=80&w=1887'),
    Barber(name: 'Thiago Costa', specialty: 'Barba e Desenhos', rating: 5.0, imageUrl: 'https://images.unsplash.com/photo-1623723389088-3fe67372932c?q=80&w=1887'),
  ];

  Barber? _selectedBarber;

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Make it transparent
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.white],
            stops: const [0.2, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step Indicator would go here
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              // Placeholder for a step indicator
              child: Text('Passo 1 de 3: Escolha o Barbeiro', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Escolha o Barbeiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _barbers.length,
                          itemBuilder: (context, index) {
                            final barber = _barbers[index];
                            final isSelected = _selectedBarber == barber;
                            return BarberCard(
                              barber: barber,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedBarber = barber;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Continue Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _selectedBarber == null ? null : () {
                  // TODO: Navigate to the next step (Date selection)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100.withOpacity(0.9),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarberCard extends StatelessWidget {
  final Barber barber;
  final bool isSelected;
  final VoidCallback onTap;

  const BarberCard({super.key, required this.barber, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Colors.blue.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: Colors.blue.shade400, width: 2) : BorderSide.none,
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(barber.imageUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(barber.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(barber.specialty, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(barber.rating.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
