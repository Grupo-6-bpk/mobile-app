import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_menu_bar.dart';
import 'package:mobile_app/pages/chat/chat_page.dart';
import 'package:mobile_app/pages/passenger_home/passenger_home_screen.dart';
import 'package:mobile_app/passenger_history/passenger_ride_history_page.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _currentPageIndex = 0;

  void updatePageIndex(int newIndex) {
    setState(() {
      _currentPageIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body:
          <Widget>[
            const PassengerHomeScreen(),
            const PassengerRideHistoryPage(),
            const ChatPage(),
            const Placeholder(),
          ][_currentPageIndex],
      bottomNavigationBar: CustomMenuBar(
        currentPageIndex: _currentPageIndex,
        onPageSelected: updatePageIndex,
      ),
    );
  }
}
