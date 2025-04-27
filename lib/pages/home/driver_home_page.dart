import 'package:flutter/material.dart';
import 'package:mobile_app/components/available_passenger_card.dart';
import 'package:mobile_app/components/custom_menu_bar.dart';
import 'package:mobile_app/pages/chat/chat_page.dart';
import 'package:mobile_app/pages/ride_history/ride_history_page.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _currentPageIndex = 0;
  
  // Dados mocados dos passageiros disponíveis
  final List<Map<String, dynamic>> _availablePassengers = [
    {
      'name': 'Jéssica Santos',
      'location': 'Av. Maripa - 5498, Centro, Toledo - PR',
      'phoneNumber': '45 98432-3230',
      'imageUrl': 'assets/images/profile1.png',
      'rating': 4.0
    },
    {
      'name': 'Ana Silva',
      'location': 'Av. Maripa - 5498, Centro, Toledo - PR',
      'phoneNumber': '45 98432-3230',
      'imageUrl': 'assets/images/profile2.png',
      'rating': 4.5
    },
    {
      'name': 'Carla Pereira',
      'location': 'Av. Maripa - 5498, Centro, Toledo - PR',
      'phoneNumber': '45 98432-3230',
      'imageUrl': 'assets/images/profile3.png',
      'rating': 5.0
    },
  ];

  // Widget da página inicial do motorista
  Widget _buildDriverHomePage() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com saudação
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boa tarde, Gabriel',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Passageiros disponíveis:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          
          // Lista de passageiros disponíveis
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                itemCount: _availablePassengers.length,
                itemBuilder: (context, index) {
                  final passenger = _availablePassengers[index];
                  return AvailablePassengerCard(
                    name: passenger['name'],
                    location: passenger['location'],
                    phoneNumber: passenger['phoneNumber'],
                    imageUrl: passenger['imageUrl'],
                    rating: passenger['rating'],
                    onAccept: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Passageiro ${passenger['name']} aceito!'),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void updatePageIndex(int index) {
      if (index == 2) {
        // Navegar para a página de chat
        Navigator.pushNamed(context, '/chat');
        return;
      }
      
      if (context.mounted) {
        setState(() {
          _currentPageIndex = index;
        });
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: <Widget>[
        _buildDriverHomePage(),
        const RideHistoryPage(),
        const ChatPage(), // Este widget não será usado diretamente, navegação é feita via route
        const Center(child: Text('Configurações em desenvolvimento', style: TextStyle(fontSize: 20))),
      ][_currentPageIndex],
      bottomNavigationBar: CustomMenuBar(
        currentPageIndex: _currentPageIndex,
        onPageSelected: updatePageIndex,
      ),
    );
  }
}