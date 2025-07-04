import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'chat/chat_list_screen.dart';
import 'passenger_home/passenger_home.dart';
import 'home/driver_home_page.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const ChatListScreen(),
    const PassengerHome(),
    const DriverHomePage(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: 'Chat',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.directions_car),
      label: 'Caronas',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.drive_eta),
      label: 'Oferecer',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next == AuthState.unauthenticated) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/login', 
          (route) => false,
        );
      }
    });
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navItems,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(currentUser?.name ?? 'Usuário'),
              accountEmail: Text(currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: currentUser?.avatarUrl != null
                    ? NetworkImage(currentUser!.avatarUrl!)
                    : null,
                child: currentUser?.avatarUrl == null
                    ? Text(_getInitials(currentUser?.name ?? 'U'))
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Conversas'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 0;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Caronas'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_eta),
              title: const Text('Oferecer Carona'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Ajuda'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sair',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await ref.read(authProvider.notifier).logout();
                if (!mounted) return;
                navigator.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }
} 