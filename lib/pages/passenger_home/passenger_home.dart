import 'package:flutter/material.dart';
import 'package:mobile_app/pages/passenger_home/passenger_home_screen.dart';
import 'package:mobile_app/pages/passenger_ride_history_page.dart';

class PassengerHome extends StatelessWidget {
  const PassengerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body:
          <Widget>[
            const PassengerHomeScreen(),
            const PassengerRideHistoryPage(),
            const ChatPage(),
            const SettingsPage(),
          ][_currentPageIndex],
      bottomNavigationBar: CustomMenuBar(
        currentPageIndex: _currentPageIndex,
        onPageSelected: updatePageIndex,
      ),
    );
  }
}
