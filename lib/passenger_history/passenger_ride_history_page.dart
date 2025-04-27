import 'package:flutter/material.dart';
import 'package:mobile_app/passenger_history/passenger_ride_detail_page.dart';

class PassengerRideHistoryPage extends StatelessWidget {
  const PassengerRideHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2133), // Cor de fundo escura conforme o print
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Histórico de viagens',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // Implementar filtro de viagens
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        children: [
          _buildRideItem(
            context,
            driverName: 'Nicolas Neto',
            address: 'Av. Maripá - 5482, Centro, Toledo - PR',
            route: 'Biapark Educação',
            dateTime: '24/03/2025 07:00',
            price: 13.90,
          ),
          const SizedBox(height: 8),
          _buildRideItem(
            context,
            driverName: 'Maria\'s Tur',
            address: 'Av. Cirne de Lima - 6489, Centro, Toledo - PR',
            route: 'Biapark Educação',
            dateTime: '24/03/2025 07:00',
            price: 15.90,
          ),
          const SizedBox(height: 8),
          _buildRideItem(
            context,
            driverName: 'Xander\'s Tur',
            address: 'Av. Cirne de Lima - 5486, Centro, Toledo - PR',
            route: 'Biapark Educação',
            dateTime: '24/03/2025 07:00',
            price: 20.90,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildRideItem(
    BuildContext context, {
    required String driverName,
    required String address,
    required String route,
    required String dateTime,
    required double price,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF272A3F), // Cor de fundo do card conforme o print
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            final parts = dateTime.split(' ');
            final date = parts[0];
            final time = parts[1];
            
            // Navegar para a página de detalhes da viagem
            showDialog(
              context: context,
              builder: (context) => PassengerRideDetailPage(
                date: date,
                address: address,
                time: time,
                title: driverName,
                vehicleInfo: 'Veículo: Carro particular',
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Ícone de carro em círculo azul
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B59ED), // Azul conforme o print
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16.0),
                // Informações da viagem
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        address,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.white70,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            route,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateTime,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Preço
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFF1F2133),
        border: Border(
          top: BorderSide(
            color: Color(0xFF272A3F),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(context, Icons.home_rounded, 'Home', false),
          _buildNavBarItem(context, Icons.directions_car_rounded, 'Caronas', true),
          _buildNavBarItem(context, Icons.chat_rounded, 'Chat', false),
          _buildNavBarItem(context, Icons.settings, 'Configurações', false),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(BuildContext context, IconData icon, String label, bool isSelected) {
    final color = isSelected ? Colors.white : Colors.white54;
    
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 