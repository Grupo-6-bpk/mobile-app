import 'package:flutter/material.dart';
import 'package:mobile_app/pages/ride_history/ride_detail_page.dart';
import 'package:mobile_app/services/ride_history_service.dart';
import 'package:mobile_app/models/ride_history.dart';
import 'package:intl/intl.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  bool _showStats = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final RideHistoryService _rideHistoryService = RideHistoryService();
  List<RideHistory> _rides = [];
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  Future<void> _loadRideHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _currentPage = 1;
      });
    }
    try {
      final response = await _rideHistoryService.getRideHistory(
        page: _currentPage,
        size: 10,
      );
      setState(() {
        if (refresh) {
          _rides = response.rides;
        } else {
          _rides.addAll(response.rides);
        }
        _currentPage = response.currentPage;
        _totalPages = response.totalPages;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  List<RideHistory> get _filteredRides {
    return _rides.where((ride) {
      return ride.departureTime.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          ride.departureTime.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
  }

  int get _totalRides => _filteredRides.length;
  double get _totalSpent => _filteredRides.fold(0.0, (sum, ride) => sum + ride.userShare);
  double get _totalDistance => _filteredRides.fold(0.0, (sum, ride) => sum + ride.distance);
  double get _totalSavings => _filteredRides.fold(0.0, (sum, ride) => sum + ride.savings);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Histórico de viagens'),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
                      color: Colors.black.withOpacity(0.05),
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
                    const SizedBox(height: 4),
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
                          icon: Icons.savings,
                          value: 'R\$ ${_totalSavings.toStringAsFixed(2)}',
                          label: 'Economia',
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
            child: _buildRidesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesList() {
    if (_isLoading && _rides.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_hasError && _rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar histórico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRideHistory(refresh: true),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (_filteredRides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma viagem encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não há viagens no período selecionado',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadRideHistory(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: _filteredRides.length + (_currentPage < _totalPages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredRides.length) {
            // Item de carregamento para paginação
            return _buildLoadingItem();
          }
          final ride = _filteredRides[index];
          return _buildRideHistoryItem(context, ride);
        },
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context, {required String label, required DateTime date, required Function(DateTime) onSelect}) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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

  Widget _buildRideHistoryItem(BuildContext context, RideHistory ride) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => RideDetailPage(ride: ride),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  radius: 22,
                  child: Icon(
                    Icons.directions_car,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ride.title != null)
                        Text(
                          ride.title!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (ride.title != null) const SizedBox(height: 2.0),
                      Text(
                        ride.title == null ? 'Viagem ${DateFormat('dd/MM/yyyy').format(ride.departureTime)}' : DateFormat('dd/MM/yyyy').format(ride.departureTime),
                        style: TextStyle(
                          fontWeight: ride.title == null ? FontWeight.bold : FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        ride.startAddress,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ride.route,
                              style: TextStyle(
                                fontSize: 11.0,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(ride.departureTime),
                            style: TextStyle(
                              fontSize: 11.0,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${ride.userShare.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
