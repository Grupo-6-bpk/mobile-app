import 'package:flutter/material.dart';

class CustomMenuBar extends StatelessWidget {
  final int currentPageIndex;
  final Function(int)? onPageSelected;

  const CustomMenuBar({
    super.key,
    this.currentPageIndex = 0,
    this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      overlayColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      destinations: const <Widget>[
        NavigationDestination(icon: Icon(Icons.home_rounded), label: "Home"),
        NavigationDestination(
          icon: Icon(Icons.directions_car_rounded),
          label: "Viagens",
        ),
        NavigationDestination(icon: Icon(Icons.chat_rounded), label: "Chat"),
        NavigationDestination(
          icon: Icon(Icons.settings_rounded),
          label: "Configurações",
        ),
      ],
      indicatorColor: Theme.of(context).colorScheme.primaryContainer,
      selectedIndex: currentPageIndex,
      onDestinationSelected: (int index) {
        if (onPageSelected != null) {
          onPageSelected!(index);
        } else {
          // Navegação direta pelo menu se não tiver um callback definido
          if (index == 2 && currentPageIndex != 2) {
            Navigator.pushNamed(context, '/chat');
          }
        }
      },
    );
  }
}
