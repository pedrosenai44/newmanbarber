import 'package:flutter/material.dart';
import 'package:newmanbarber/telas/appointment_page.dart';
import 'package:newmanbarber/telas/login_page.dart';
import 'package:newmanbarber/telas/profile_page.dart';

// --- Data Model for a Service ---
class Service {
  final String name;
  final String duration;
  final String price;
  final String imageUrl;
  final String category;

  Service({
    required this.name,
    required this.duration,
    required this.price,
    required this.imageUrl,
    required this.category,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- State Variables ---

  final List<Service> _allServices = [
    Service(name: 'Corte Masculino', duration: '30 min', price: 'R\$ 25', imageUrl: 'https://www.styleseat.com/blog/wp-content/uploads/2021/09/barber-terms-hero-scaled-1-1140x850.jpg', category: 'Cortes'),
    Service(name: 'Barba Completa', duration: '20 min', price: 'R\$ 15', imageUrl: 'https://media.gettyimages.com/id/872361244/pt/foto/man-getting-his-beard-trimmed-with-electric-razor.jpg?s=2048x2048&w=gi&k=20&c=ndjW7M52LeGSslcjj_E6caOwQi78WCOYUiWpiuv5BhM=', category: 'Barba'),
    Service(name: 'Corte Infantil', duration: '25 min', price: 'R\$ 20', imageUrl: 'https://cdn.prod.website-files.com/5cb569e54ca2fddd5451cbb2/64ab496fde4797e734018c2f_Skin-Fade-Hero.jpg', category: 'Cortes'),
    Service(name: 'Sobrancelha', duration: '10 min', price: 'R\$ 5', imageUrl: 'https://bluebarbearia.shop/img/sobrancelha.png', category: 'Especial'),
    Service(name: 'Corte e Barba', duration: '50 min', price: 'R\$ 40', imageUrl: 'https://peoplesbarber.com/wp-content/uploads/Peoples_02.jpg', category: 'Combos'),
  ];

  List<Service> _displayedServices = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _displayedServices = List.from(_allServices);
    _searchController.addListener(_updateDisplayedServices);
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateDisplayedServices);
    _searchController.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  void _updateDisplayedServices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _displayedServices = _allServices.where((service) {
        final matchesCategory = _selectedFilter == 'Todos' || service.category == _selectedFilter;
        final matchesSearch = service.name.toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _updateDisplayedServices();
  }

  void _handleMenuSelection(String result) {
    if (result == 'logout') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } else if (result == 'profile') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final profileMenuItems = <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(value: 'profile', child: ListTile(leading: Icon(Icons.person), title: Text('Ver Perfil'))),
      const PopupMenuItem<String>(value: 'logout', child: ListTile(leading: Icon(Icons.exit_to_app), title: Text('Sair'))),
    ];

    return Scaffold(
      backgroundColor: Colors.blue.shade300,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('NewManBarber', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'serif', color: Colors.white, fontSize: 24)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar serviços...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: PopupMenuButton<String>(
                  onSelected: _handleMenuSelection,
                  itemBuilder: (BuildContext context) => profileMenuItems,
                  child: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.grey)),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
        ),
      ),
      body: Container(
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
            FilterButtons(
              selectedFilter: _selectedFilter,
              onFilterSelected: _onFilterSelected,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _displayedServices.length,
                itemBuilder: (context, index) {
                  final service = _displayedServices[index];
                  return ServiceCard(
                    service: service,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterButtons extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const FilterButtons({super.key, required this.selectedFilter, required this.onFilterSelected});

  @override
  Widget build(BuildContext context) {
    final List<String> filters = ['Todos', 'Cortes', 'Barba', 'Combos', 'Especial'];
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 16 : 8, right: index == filters.length - 1 ? 16 : 0),
            child: ChoiceChip(
              label: Text(filter),
              selected: selectedFilter == filter,
              onSelected: (bool selected) {
                if (selected) {
                  onFilterSelected(filter);
                }
              },
              backgroundColor: Colors.white.withOpacity(0.7),
              selectedColor: Colors.white,
              labelStyle: TextStyle(color: selectedFilter == filter ? Colors.black : Colors.black54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final Service service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
            child: Image.network(
              service.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)));
              },
            ),
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
                      Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(service.duration, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentPage(service: service),
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
                  child: Text(service.price),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
