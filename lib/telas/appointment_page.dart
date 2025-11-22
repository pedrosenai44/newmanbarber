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
  // --- Dados dos Barbeiros (Com links corrigidos) ---
  final List<Barber> _barbers = [
    Barber(
      name: 'Carlos Silva',
      specialty: 'Cortes Clássicos',
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1585747833871-693963cbeee9?auto=format&fit=crop&q=80&w=200',
    ),
    Barber(
      name: 'Rafael Santos',
      specialty: 'Fade e Degradê',
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200',
    ),
    Barber(
      name: 'Thiago Costa',
      specialty: 'Barba e Desenhos',
      rating: 5.0,
      imageUrl: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&q=80&w=200',
    ),
  ];

  // --- Variáveis de Estado do Agendamento ---
  int _currentStep = 0; // 0: Barbeiro, 1: Data, 2: Horário, 3: Resumo
  Barber? _selectedBarber;
  DateTime? _selectedDate;
  String? _selectedTime;

  // Horários disponíveis (Exemplo)
  final List<String> _timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00',
    '13:00', '13:30', '14:00', '14:30', '15:00',
    '16:00', '16:30', '17:00', '17:30', '18:00',
  ];

  // --- Lógica de Navegação ---
  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _confirmAppointment();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _confirmAppointment() {
    // Aqui salvaremos no Firebase futuramente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Agendamento Confirmado com Sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context); // Volta para a Home
  }

  // --- Construção da Tela ---
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
          onPressed: _prevStep,
        ),
      ),
      body: Container(
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
            // Indicador de Passos
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(0, 'Barbeiro'),
                  _buildLine(),
                  _buildStepIndicator(1, 'Data'),
                  _buildLine(),
                  _buildStepIndicator(2, 'Horário'),
                ],
              ),
            ),
            
            // Conteúdo Variável
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
                child: _buildCurrentStepContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _canProceed() ? _nextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade400,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: Text(
            _currentStep == 3 ? 'Confirmar Agendamento' : 'Continuar',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Verifica se pode avançar
  bool _canProceed() {
    if (_currentStep == 0) return _selectedBarber != null;
    if (_currentStep == 1) return _selectedDate != null;
    if (_currentStep == 2) return _selectedTime != null;
    return true;
  }

  // Conteúdo de cada passo
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBarberSelection();
      case 1:
        return _buildDateSelection();
      case 2:
        return _buildTimeSelection();
      case 3:
        return _buildSummary();
      default:
        return const SizedBox.shrink();
    }
  }

  // Passo 1: Barbeiros
  Widget _buildBarberSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escolha o Profissional', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _barbers.length,
            itemBuilder: (context, index) {
              final barber = _barbers[index];
              final isSelected = _selectedBarber == barber;
              return Card(
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected ? BorderSide(color: Colors.blue.shade400, width: 2) : BorderSide.none,
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  onTap: () => setState(() => _selectedBarber = barber),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(barber.imageUrl),
                    radius: 25,
                  ),
                  title: Text(barber.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(barber.specialty),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(barber.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Passo 2: Data
  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escolha a Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: CalendarDatePicker(
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            onDateChanged: (date) => setState(() => _selectedDate = date),
          ),
        ),
      ],
    );
  }

  // Passo 3: Horário
  Widget _buildTimeSelection() {
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
            itemCount: _timeSlots.length,
            itemBuilder: (context, index) {
              final time = _timeSlots[index];
              final isSelected = _selectedTime == time;
              return ChoiceChip(
                label: Text(time),
                selected: isSelected,
                onSelected: (selected) => setState(() => _selectedTime = selected ? time : null),
                selectedColor: Colors.blue.shade400,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              );
            },
          ),
        ),
      ],
    );
  }

  // Passo 4: Resumo
  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumo do Agendamento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildSummaryRow(Icons.content_cut, 'Serviço', widget.service.name),
        _buildSummaryRow(Icons.attach_money, 'Valor', widget.service.price),
        const Divider(),
        _buildSummaryRow(Icons.person, 'Barbeiro', _selectedBarber?.name ?? ''),
        _buildSummaryRow(Icons.calendar_today, 'Data', _selectedDate.toString().split(' ')[0]),
        _buildSummaryRow(Icons.access_time, 'Horário', _selectedTime ?? ''),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade400),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  // Auxiliar visual para o indicador de passos
  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: isActive ? Colors.blue.shade800 : Colors.blue.shade200,
          child: Text((step + 1).toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLine() {
    return Container(width: 30, height: 2, color: Colors.white54, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15));
  }
}
