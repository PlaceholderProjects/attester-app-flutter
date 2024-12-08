import 'dart:async';
import 'dart:convert';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pannable_rating_bar/flutter_pannable_rating_bar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:placeholder/qrScan/scanner_barcode.dart';
import 'package:placeholder/qrScan/scanner_error.dart';
import 'package:reown_appkit/reown_appkit.dart';

class BarcodeScannerWithOverlay extends StatefulWidget {
  final ReownAppKitModal appKitModal;
  final Function(bool linkMode) reinitialize;
  final bool linkMode;

  const BarcodeScannerWithOverlay({
    super.key,
    required this.appKitModal,
    required this.reinitialize,
    this.linkMode = false,
  });

  @override
  _BarcodeScannerWithOverlayState createState() =>
      _BarcodeScannerWithOverlayState();
}

class _BarcodeScannerWithOverlayState extends State<BarcodeScannerWithOverlay>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    autoStart: true,
    torchEnabled: false,
    useNewCameraSelector: true,
  );
  final List<ReownAppKitModalNetworkInfo> _selectedChains = [];
  bool _shouldDismissQrCode = true;
  double rating = 0;
  String qRPayload = '';

  StreamSubscription<Object?>? _subscription;

  String userWalletAddress = '';

  late AlertDialog alert;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = controller.barcodes.listen(restartQr);

        unawaited(controller.start());
        break;
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
        break;
    }
  }

  void restartQr(BarcodeCapture event) {
    if (mounted) {
      setState(() {
        qRPayload = event.barcodes.first.displayValue!;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    _subscription = controller.barcodes.listen(restartQr);

    unawaited(controller.start());
    widget.appKitModal.onModalConnect.subscribe(_onModalConnect);
    widget.appKitModal.onModalUpdate.subscribe(_onModalUpdate);
    widget.appKitModal.onModalNetworkChange.subscribe(_onModalNetworkChange);
    widget.appKitModal.onModalDisconnect.subscribe(_onModalDisconnect);
    widget.appKitModal.onModalError.subscribe(_onModalError);
    //
    widget.appKitModal.appKit!.onSessionConnect.subscribe(
      _onSessionConnect,
    );
    widget.appKitModal.appKit!.onSessionAuthResponse.subscribe(
      _onSessionAuthResponse,
    );
    widget.appKitModal.onModalDisconnect.subscribe(
      _onModalDisconnect,
    );
  }

  void _onSessionAuthResponse(SessionAuthResponse? response) {
    if (response?.session != null) {
      setState(() => _selectedChains.clear());
    }
  }

  void _onModalConnect(ModalConnect? event) async {
    setState(() {});
  }

  void _onModalUpdate(ModalConnect? event) {
    setState(() {});
  }

  void _onModalNetworkChange(ModalNetworkChange? event) {
    setState(() {});
  }

  void _onModalDisconnect(ModalDisconnect? event) {
    setState(() {});
  }

  void _onModalError(ModalError? event) {
    setState(() {});
  }

  void _onSessionConnect(SessionConnect? event) async {
    if (event == null) return;

    userWalletAddress = event.session.self.publicKey;

    setState(() => _selectedChains.clear());

    if (_shouldDismissQrCode && Navigator.canPop(context)) {
      _shouldDismissQrCode = false;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() async {
    widget.appKitModal.onModalConnect.unsubscribe(_onModalConnect);
    widget.appKitModal.onModalUpdate.unsubscribe(_onModalUpdate);
    widget.appKitModal.onModalNetworkChange.unsubscribe(_onModalNetworkChange);
    widget.appKitModal.onModalDisconnect.unsubscribe(_onModalDisconnect);
    widget.appKitModal.onModalError.unsubscribe(_onModalError);
    widget.appKitModal.onModalDisconnect.unsubscribe(
      _onModalDisconnect,
    );
    widget.appKitModal.appKit!.onSessionAuthResponse.unsubscribe(
      _onSessionAuthResponse,
    );
    widget.appKitModal.appKit!.onSessionConnect.unsubscribe(
      _onSessionConnect,
    );
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
    await controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset(0, 0)),
      width: 200,
      height: 200,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: MobileScanner(
              fit: BoxFit.cover,
              controller: controller,
              scanWindow: scanWindow,
              errorBuilder: (context, error, child) {
                return ScannerErrorWidget(error: error);
              },
              overlayBuilder: (context, constraints) {
                return Container(
                  margin: const EdgeInsets.only(top: 500),
                  child: ScannedBarcodeLabel(
                      barcodes: controller.barcodes,
                      onTokenScanned: updatePayload),
                );
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              if (!value.isInitialized ||
                  !value.isRunning ||
                  value.error != null) {
                return const SizedBox();
              }

              return CustomPaint(
                painter: ScannerOverlay(scanWindow: scanWindow),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: PannableRatingBar(
                rate: rating,
                onChanged: updateRating,
                spacing: 20,
                items: List.generate(
                  5,
                  (index) => const RatingWidget(
                    selectedColor: Colors.yellow,
                    unSelectedColor: Colors.grey,
                    child: Icon(
                      Icons.star,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              height: 100,
              child: AppKitModalConnectButton(
                appKit: widget.appKitModal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void updatePayload(String payload) {
    qRPayload = payload;
    // print(qRPayload);
  }

  void updateRating(double value) {
    setState(() {
      rating = value;
      final chainId = widget.appKitModal.selectedChain?.chainId ?? '';
      if (chainId.isNotEmpty) {
        final namespace =
        ReownAppKitModalNetworks.getNamespaceForChainId(
          chainId,
        );
        userWalletAddress =
            widget.appKitModal.session?.getAddress(namespace) ?? '';
      }
      if(userWalletAddress.isEmpty){
        const snackBar = SnackBar(
          /// need to set following properties for best effect of awesome_snackbar_content
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Uh Oh!',
            message: 'Please connect your wallet to rate',

            /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
            contentType: ContentType.failure,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        rating = 0;
        setState(() {});
        return;
      }
      //alert dialog with submit rating
      alert = AlertDialog(
        title: const Text('Submit Rating'),
        content: const Text('Are you sure you want to submit this rating?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              print('Publisher Wallet Address $qRPayload');
              final chainId = widget.appKitModal.selectedChain?.chainId ?? '';
              if (chainId.isNotEmpty) {
                final namespace =
                    ReownAppKitModalNetworks.getNamespaceForChainId(
                  chainId,
                );
                userWalletAddress =
                    widget.appKitModal.session?.getAddress(namespace) ?? '';
              }
              print('User Wallet Address$userWalletAddress');
              setState(() {});
              rating = 0;
              setState(() {});
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              //show small loader alert
              showDialog(
                context: context,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              final chainId = widget.appKitModal.selectedChain?.chainId ?? '';
              if (chainId.isNotEmpty) {
                final namespace =
                    ReownAppKitModalNetworks.getNamespaceForChainId(
                  chainId,
                );
                userWalletAddress =
                    widget.appKitModal.session?.getAddress(namespace) ?? '';
              }
              var headers = {'Content-Type': 'application/json'};
              var data = json.encode({
                "publisherAddress": "$qRPayload",
                "userAddress": "${userWalletAddress}",
                "rating": value.toInt(),
                "signature": "0x123"
              });
              var dio = Dio();
              var response = await dio.request(
                'https://liz4000.athelstantechnolabs.com/api/attestation',
                options: Options(
                  method: 'POST',
                  headers: headers,
                ),
                data: data,
              );

              if (response.statusCode == 200) {
                print(response.data);
                Navigator.of(context).pop();
                const snackBar = SnackBar(
                  /// need to set following properties for best effect of awesome_snackbar_content
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: 'Thank you for rating!',
                    message: 'Checkout for the reputation score to validate',

                    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                    contentType: ContentType.success,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
                rating = 0;
                setState(() {});
              } else {
                Navigator.of(context).pop();
                const snackBar = SnackBar(
                  /// need to set following properties for best effect of awesome_snackbar_content
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: 'Uh Oh!',
                    message: 'Could not submit rating',

                    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                    contentType: ContentType.failure,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
                print(response.statusMessage);
                rating = 0;
                setState(() {});
              }
            },
            child: const Text('Submit'),
          ),
        ],
      );
      showDialog(context: context, builder: (context) => alert);
    });
  }
}

class ScannerOverlay extends CustomPainter {
  const ScannerOverlay({
    required this.scanWindow,
    this.borderRadius = 12.0,
  });

  final Rect scanWindow;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    // we need to pass the size to the custom paint widget
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          scanWindow,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOver;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    // First, draw the background,
    // with a cutout area that is a bit larger than the scan window.
    // Finally, draw the scan window itself.
    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) {
    return scanWindow != oldDelegate.scanWindow ||
        borderRadius != oldDelegate.borderRadius;
  }
}
