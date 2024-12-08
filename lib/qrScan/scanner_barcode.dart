import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannedBarcodeLabel extends StatelessWidget {
  const ScannedBarcodeLabel({
    super.key,
    required this.barcodes,
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
