import 'package:flutter/material.dart';
import 'package:qr_barcode_scanner/classes/qr_result_class.dart';
import 'package:qr_barcode_scanner/pages/history_screen_page.dart';
import 'package:qr_barcode_scanner/pages/info_screen_page.dart';
import 'package:qr_barcode_scanner/pages/scanner_screen_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<QRResult> _scanHistory = [];

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      ScannerScreen(onQRScanned: _addToHistory),
      HistoryScreen(history: _scanHistory),
      const InfoScreen(),
    ]);
  }

  void _addToHistory(QRResult result) {
    setState(() {
      _scanHistory.insert(0, result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
