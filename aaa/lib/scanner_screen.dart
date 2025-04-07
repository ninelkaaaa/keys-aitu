import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'confirm_action_screen.dart';

class ScannerScreen extends StatefulWidget {
  final String action;

  const ScannerScreen({super.key, required this.action});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController();
  String scannedCode = "Отсканируйте код";
  bool isScanning = false;

  void _startScanning() {
    setState(() {
      isScanning = true;
      scannedCode = "Сканирование...";
    });
  }

  void _onDetect(BarcodeCapture barcode) {
    if (!isScanning) return;

    final String? code = barcode.barcodes.first.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() {
        scannedCode = "Сканировано: $code";
        isScanning = false;
      });

      // Переход на экран подтверждения
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmActionScreen(
            cabinetCode: code,
            action: widget.action,
          ),
        ),
      ).then((result) {
        // Возврат после подтверждения или отмены
        setState(() {
          scannedCode = "Отсканируйте код";
        });
      });
    } else {
      setState(() {
        scannedCode = "Не удалось распознать код";
        isScanning = false;
      });
    }
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Сканер - ${widget.action} ключ")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Для выполнения действия нажмите кнопку сканирования",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: MobileScanner(
              controller: scannerController,
              onDetect: _onDetect,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            scannedCode,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _startScanning,
            child: const Text("Сканировать"),
          ),
        ],
      ),
    );
  }
}
