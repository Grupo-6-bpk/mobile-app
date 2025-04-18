import 'package:flutter/material.dart';
import 'package:mobile_app/pages/ride_history/ride_detail_page.dart';
import 'package:intl/intl.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  bool _showStats = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Dados mockados de viagens para calcular estatísticas
  final List<Map<String, dynamic>> _mockRides = [
    {
      'date': '23/04/2025',
      'address': 'Av. Cirne de Lima - 5486, Centro, Toledo - PR',
      'route': 'Biapark/Educação',
      'time': '07:00',
      'price': 20.90,
      'distance': 8.5,
      'timestamp': DateTime(2025, 4, 23, 7, 0),
    },
    {
      'date': '23/04/2025',
      'address': 'Av. Cirne de Lima - 5486, Centro, Toledo - PR',
      'route': 'Biapark/Educação',
      'time': '18:00',
      'price': 50.00,
      'distance': 12.2,
      'timestamp': DateTime(2025, 4, 23, 18, 0),
    },
    {
      'date': '24/03/2025',
      'address': 'Av. Cirne de Lima - 5486, Centro, Toledo - PR',
      'route': 'Biapark/Educação',
      'time': '07:00',
      'price': 20.90,
      'title': 'Xander\'s Tur',
      'vehicleInfo': 'Veículo: Sonic 3.0 Turbo, Cor: Branco',
      'distance': 8.5,
      'timestamp': DateTime(2025, 3, 24, 7, 0),
    },
    {
      'date': '15/03/2025',
      'address': 'Av. Parigot de Souza - 1200, Jardim, Toledo - PR',
      'route': 'Centro/Faculdade',
      'time': '19:30',
      'price': 15.50,
      'distance': 5.8,
      'timestamp': DateTime(2025, 3, 15, 19, 30),
    },
    {
      'date': '10/03/2025',
      'address': 'Rua Jorge Lacerda - 320, Santa Maria, Toledo - PR',
      'route': 'Biapark/Hospital',
      'time': '08:15',
      'price': 22.00,
      'distance': 9.2,
      'timestamp': DateTime(2025, 3, 10, 8, 15),
    },
  ];

  // Filtrar viagens por intervalo de datas
  List<Map<String, dynamic>> get _filteredRides {
    return _mockRides.where((ride) {
      DateTime rideDate = ride['timestamp'] as DateTime;
      return rideDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          rideDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Calcular estatísticas
  int get _totalRides => _filteredRides.length;
  double get _totalSpent =>
      _filteredRides.fold(0.0, (sum, ride) => sum + (ride['price'] as double));
  double get _totalDistance => _filteredRides.fold(
    0.0,
    (sum, ride) => sum + (ride['distance'] as double),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Histórico de viagens'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.analytics_outlined : Icons.analytics),
            onPressed: () {
              setState(() {
                _showStats = !_showStats;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Painel de estatísticas
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showStats ? 260 : 0,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estatísticas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filtro de datas
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateFilter(
                            context,
                            label: 'Data inicial',
                            date: _startDate,
                            onSelect: (date) {
                              setState(() {
                                _startDate = date;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDateFilter(
                            context,
                            label: 'Data final',
                            date: _endDate,
                            onSelect: (date) {
                              setState(() {
                                _endDate = date;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cards de estatísticas
                    Row(
                      children: [
                        _buildStatCard(
                          context,
                          icon: Icons.directions_car,
                          value: _totalRides.toString(),
                          label: 'Viagens',
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.attach_money,
                          value: 'R\$ ${_totalSpent.toStringAsFixed(2)}',
                          label: 'Gastos',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatCard(
                          context,
                          icon: Icons.route,
                          value: '${_totalDistance.toStringAsFixed(1)} km',
                          label: 'Distância',
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.group,
                          value: '${_totalRides * 3}',
                          label: 'Passageiros',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de viagens
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              itemCount: _filteredRides.length,
              itemBuilder: (context, index) {
                final ride = _filteredRides[index];
                return _buildRideHistoryItem(
                  context,
                  date: ride['date'],
                  address: ride['address'],
                  route: ride['route'],
                  time: ride['time'],
                  price: ride['price'],
                  title: ride['title'],
                  vehicleInfo:
                      ride['vehicleInfo'] ??
                      'Veículo: Sonic 3.0 Turbo, Cor: Branco',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(
    BuildContext context, {
    required String label,
    required DateTime date,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideHistoryItem(
    BuildContext context, {
    required String date,
    required String address,
    required String route,
    required String time,
    required double price,
    String? title,
    String vehicleInfo = 'Veículo: Sonic 3.0 Turbo, Cor: Branco',
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            // Navegar para a página de detalhes da viagem
            showDialog(
              context: context,
              builder:
                  (context) => RideDetailPage(
                    date: date,
                    address: address,
                    time: time,
                    title: title,
                    vehicleInfo: vehicleInfo,
                  ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  radius: 24,
                  child: Icon(
                    Icons.directions_car,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      if (title != null) const SizedBox(height: 4.0),
                      Text(
                        title == null ? 'Viagem $date' : date,
                        style: TextStyle(
                          fontWeight:
                              title == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            route,
                            style: TextStyle(
                              fontSize: 12.0,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 12.0,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
