import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('QR Code Scanner App'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'QR Scanner',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.qr_code_scanner),
                      children: [
                        const Text('A simple and efficient QR code scanner app.'),
                      ],
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Privacy'),
                  subtitle: const Text('Your scans are stored locally'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Privacy Information'),
                        content: const Text(
                          'This app stores your scan history locally on your device. '
                          'No data is sent to external servers. '
                          'Camera access is only used for scanning QR codes.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help'),
                  subtitle: const Text('How to use the app'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('How to Use'),
                        content: const Text(
                          '1. Grant camera permission\n'
                          '2. Point your camera at a QR code\n'
                          '3. The code will be scanned automatically\n'
                          '4. Links will offer to open in your browser\n'
                          '5. View your scan history in the History tab',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
