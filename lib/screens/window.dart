import 'dart:io';
import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/constant.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:path/path.dart' as p;

class WindowBarcodeScanner extends StatefulWidget {
  final String lineColor;
  final String cancelButtonText;
  final bool isShowFlashIcon;
  final ScanType scanType;
  final Function(String) onScanned;

  const WindowBarcodeScanner({
    Key? key,
    required this.lineColor,
    required this.cancelButtonText,
    required this.isShowFlashIcon,
    required this.scanType,
    required this.onScanned,
  }) : super(key: key);

  @override
  State<WindowBarcodeScanner> createState() => _WindowBarcodeScannerState();
}

class _WindowBarcodeScannerState extends State<WindowBarcodeScanner> {
  WebviewController controller = WebviewController();
  bool isPermissionGranted = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kScanPageTitle),
      ),
      body: FutureBuilder<bool>(
          future: initPlatformState(
            controller: controller,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Webview(
                    controller,
                    permissionRequested: (url, permissionKind, isUserInitiated) => _onPermissionRequested(
                        url: url, kind: permissionKind, isUserInitiated: isUserInitiated, context: context, isPermissionGranted: isPermissionGranted),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      {required String url,
      required WebviewPermissionKind kind,
      required bool isUserInitiated,
      required BuildContext context,
      required bool isPermissionGranted}) async {
    final WebviewPermissionDecision? decision;
    // if (!isPermissionGranted) {
    //   decision = await showDialog<WebviewPermissionDecision>(
    //     context: context,
    //     builder: (BuildContext context) => AlertDialog(
    //       title: const Text('Permission requested'),
    //       content: Text('\'${kind.name}\' permission is require to scan qr/barcode'),
    //       actions: <Widget>[
    //         TextButton(
    //           onPressed: () {
    //             Navigator.pop(context, WebviewPermissionDecision.deny);
    //             isPermissionGranted = false;
    //           },
    //           child: const Text('Deny'),
    //         ),
    //         TextButton(
    //           onPressed: () {
    //             Navigator.pop(context, WebviewPermissionDecision.allow);
    //             isPermissionGranted = true;
    //           },
    //           child: const Text('Allow'),
    //         ),
    //       ],
    //     ),
    //   );
    // } else {
    //   decision = WebviewPermissionDecision.allow;
    // }

    // return decision ?? WebviewPermissionDecision.none;
    return WebviewPermissionDecision.allow;
  }

  String getAssetFileUrl({required String asset}) {
    final assetsDirectory = p.join(p.dirname(Platform.resolvedExecutable), 'data', 'flutter_assets', asset);
    return Uri.file(assetsDirectory).toString();
  }

  Future<bool> initPlatformState({required WebviewController controller}) async {
    String? barcodeNumber;

    try {
      await controller.initialize();
      await controller.loadUrl(getAssetFileUrl(asset: PackageConstant.barcodeFilePath));

      /// Listen to web to receive barcode
      controller.webMessage.listen((event) async {
        if (event['methodName'] == "successCallback") {
          if (event['data'] is String && event['data'].isNotEmpty && barcodeNumber == null) {
            barcodeNumber = event['data'];
            widget.onScanned(barcodeNumber!);
          }
        }
      });
    } catch (e) {
      rethrow;
    }
    return true;
  }

  @override
  void dispose() {
    try {
      controller.stop();
      controller.dispose();
    } catch (_) {}

    // TODO: implement dispose
    super.dispose();
  }
}
