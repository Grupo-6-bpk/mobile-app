// caronas_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_app/pages/passager_home/passager_detail_home.dart';

class CaronasScreen extends StatefulWidget {
  const CaronasScreen({super.key});

  @override
  State<CaronasScreen> createState() => _CaronasScreenState();
}

class _CaronasScreenState extends State<CaronasScreen> {
  int _currentPageIndex = 1;

  void updatePageIndex(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  final List<Map<String, dynamic>> caronas = [
    {
      'nome': 'Jéssica Santos',
      'local': 'Av. Maripa - 549B, Centro, Toledo - PR',
      'horario': '07h00',
      'preco': 'R\$935.00',
      'estrelas': 4,
      'avatar': 'https://i.pravatar.cc/150?img=47',
    },
    {
      'nome': 'Nicolas Neto',
      'local': 'Av. Maripa - 549B, Centro, Toledo - PR',
      'horario': '07h00',
      'preco': 'R\$535.00',
      'estrelas': 3,
      'avatar': 'https://i.pravatar.cc/150?img=12',
    },
    {
      'nome': 'Pedro Neto',
      'local': 'Av. Maripa - 549B, Centro, Toledo - PR',
      'horario': '07h00',
      'preco': 'R\$335.00',
      'estrelas': 4,
      'avatar': 'https://i.pravatar.cc/150?img=23',
    },
    {
      'nome': "Maria's Tur",
      'local': 'Av. Maripa - 549B, Centro, Toledo - PR',
      'horario': '07h00',
      'preco': 'R\$235.00',
      'estrelas': 3,
      'avatar': 'https://i.pravatar.cc/150?img=30',
    },
  ];

void showPassagerDetailHome(BuildContext context, Map<String, dynamic> carona) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    barrierDismissible: true,
    // ignore: deprecated_member_use
    barrierColor: theme.colorScheme.surface.withOpacity(0.8), // Fundo opaco com base no tema
    builder: (_) => Center(
      child: Material(
        color: theme.cardColor, // Cor de fundo do modal conforme o tema
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PassagerDetailHome(carona: carona),
          ),
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Boa tarde, Gabriel',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Caronas Disponíveis:',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: caronas.length,
                  itemBuilder: (context, index) {
                    final carona = caronas[index];
                    return CaronaCard(
                      carona: carona,
                      onTap: () => showPassagerDetailHome(context, carona),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaronaCard extends StatelessWidget {
  final Map<String, dynamic> carona;
  final VoidCallback onTap;

  const CaronaCard({super.key, required this.carona, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(carona['avatar']),
                  radius: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              carona['nome'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: onTap,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saída: ${carona['local']}',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      Text(
                        'Horário de saída: ${carona['horario']}',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      if (carona.containsKey('preco'))
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            'Valor máximo da viagem: ${carona['preco']}',
                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.secondary),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < carona['estrelas'] ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              'Solicitar',
                              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
