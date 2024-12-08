import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannedBarcodeLabel extends StatelessWidget {
  final Function(String)? onTokenScanned;

  const ScannedBarcodeLabel({
    super.key,
    required this.barcodes,
    this.onTokenScanned,
  });

  final Stream<BarcodeCapture> barcodes;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: barcodes,
      builder: (context, snapshot) {
        final scannedBarcodes = snapshot.data?.barcodes ?? [];
        if (scannedBarcodes.isEmpty) {
          return const Text(
            'Let\'s Scan the Ad!',
            overflow: TextOverflow.fade,
            style: TextStyle(color: Colors.white, fontSize: 20),
          );
        }
        onTokenScanned!(scannedBarcodes.first.displayValue!);
        String? token = scannedBarcodes.first.displayValue;
        return Text(
          token!,
          overflow: TextOverflow.fade,
          style: const TextStyle(color: Colors.white),
        );
      },
    );
  }
}
