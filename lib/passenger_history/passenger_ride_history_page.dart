import 'package:flutter/material.dart';
import 'package:mobile_app/passenger_history/passenger_ride_detail_page.dart';

class PassengerRideHistoryPage extends StatelessWidget {
  const PassengerRideHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Histórico de viagens',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onBackground),
            onPressed: () {
              // Implementar filtro de viagens
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
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
      ),
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              route,
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateTime,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
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
} 