import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_barcode_scanner/classes/qr_result_class.dart';
import 'package:url_launcher/url_launcher.dart';

class ScannerScreen extends StatefulWidget {
  final Function(QRResult) onQRScanned;

  const ScannerScreen({Key? key, required this.onQRScanned}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isFlashOn = false;
  bool _hasPermission = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.status;
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'Camera permission is permanently denied. Please enable it in Settings to use the QR scanner.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
                // Check permission again when returning from settings
                _checkPermission();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    } else {
      // Permission already granted
      setState(() {
        _hasPermission = true;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleQRCode(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final code = barcode.rawValue ?? '';
      
      if (code.isNotEmpty) {
        // Stop scanning
        setState(() {
          _isScanning = false;
        });
        
        final result = QRResult(
          data: code,
          timestamp: DateTime.now(),
          type: _getQRType(code),
        );
        
        widget.onQRScanned(result);
        
        if (result.isUrl) {
          _showLaunchDialog(code);
        } else {
          _showResultDialog(code);
        }
      }
    }
  }

  String _getQRType(String data) {
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return 'URL';
    } else if (data.startsWith('tel:')) {
      return 'Phone';
    } else if (data.startsWith('mailto:')) {
      return 'Email';
    } else if (data.startsWith('wifi:')) {
      return 'WiFi';
    } else {
      return 'Text';
    }
  }

  void _showLaunchDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Link?'),
        content: Text('Do you want to open this link?\n\n$url'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(url);
              try {
                print('Attempting to launch URL: $url');
                print('Parsed URI: $uri');
                
                final canLaunch = await canLaunchUrl(uri);
                print('Can launch URL: $canLaunch');
                
                if (canLaunch) {
                  final result = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  print('Launch result: $result');
                } else {
                  print('Cannot launch URL');
                  // Store context reference before async operation
                  final currentContext = context;
                  if (mounted && currentContext.mounted) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(content: Text('Could not open link')),
                    );
                  }
                }
              } catch (e) {
                print('Error launching URL: $e');
                // Store context reference before async operation
                final currentContext = context;
                if (mounted && currentContext.mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('Error opening link: $e')),
                  );
                }
              }
              _resumeScanning();
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(String data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getQRType(data)}'),
            const SizedBox(height: 8),
            Text('Data: $data'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: data));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
              _resumeScanning();
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _resumeScanning() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await controller.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
        ],
      ),
      body: _hasPermission
          ? Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: _handleQRCode,
                      ),
                      // Custom overlay
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.width * 0.8,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                // Corner decorations
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 6,
                                        ),
                                        left: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 6,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 6,
                                        ),
                                        right: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 6,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 6,
                                        ),
                                        left: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 6,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 6,
                                        ),
                                        right: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 6,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Point your camera at a QR code',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The QR code will be scanned automatically',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 64),
                  const SizedBox(height: 16),
                  const Text('Camera permission required'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _requestPermission,
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            ),
    );
  }
}
