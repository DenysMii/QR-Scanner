import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_barcode_scanner/classes/qr_result_class.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatelessWidget {
  final List<QRResult> history;

  const HistoryScreen({Key? key, required this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
      ),
      body: history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64),
                  SizedBox(height: 16),
                  Text('No scans yet'),
                  SizedBox(height: 8),
                  Text('Scanned QR codes will appear here'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final result = history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(_getTypeIcon(result.type)),
                    ),
                    title: Text(
                      result.data,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${result.type} • ${_formatTime(result.timestamp)}',
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'copy',
                          child: const Row(
                            children: [
                              Icon(Icons.copy),
                              SizedBox(width: 8),
                              Text('Copy'),
                            ],
                          ),
                        ),
                        if (result.isUrl)
                          PopupMenuItem(
                            value: 'open',
                            child: const Row(
                              children: [
                                Icon(Icons.open_in_new),
                                SizedBox(width: 8),
                                Text('Open'),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (value) async {
                        if (value == 'copy') {
                          Clipboard.setData(ClipboardData(text: result.data));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
                        } else if (value == 'open' && result.isUrl) {
                          final uri = Uri.parse(result.data);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(result.type),
                          content: SingleChildScrollView(
                            child: Text(result.data),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'URL':
        return Icons.link;
      case 'Phone':
        return Icons.phone;
      case 'Email':
        return Icons.email;
      case 'WiFi':
        return Icons.wifi;
      default:
        return Icons.text_fields;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
