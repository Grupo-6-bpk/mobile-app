import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_menu_bar.dart';
import 'package:mobile_app/pages/passager_home/passager_home.dart';
import 'package:mobile_app/pages/ride_history/ride_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    void updatePageIndex(int index) {
      if (context.mounted) {
        setState(() {
          _currentPageIndex = index;
        });
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body:
          <Widget>[
            const CaronasScreen(),
            const RideHistoryPage(),
            const Placeholder(),
            const Placeholder(),
            const Placeholder(),
          ][_currentPageIndex],
      bottomNavigationBar: CustomMenuBar(
        currentPageIndex: _currentPageIndex,
        onPageSelected: updatePageIndex,
      ),
    );
  }
}
