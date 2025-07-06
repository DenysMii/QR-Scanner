class QRResult {
  final String data;
  final DateTime timestamp;
  final String type;

  QRResult({
    required this.data,
    required this.timestamp,
    required this.type,
  });

  bool get isUrl => Uri.tryParse(data) != null && 
      (data.startsWith('http://') || data.startsWith('https://'));
}