import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'confirm_action_screen.dart';
import 'dart:convert';

class ScannerScreen extends StatefulWidget {
  final String action;
  final int userId;
  const ScannerScreen({
    super.key,
    required this.action,
    required this.userId,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isActive = false;
  bool _scanned = false;
  bool _torchOn = false;                       // 🔦 новое состояние
  String _hint = "Отсканируйте QR‑код ключа";

  void _start() {
    setState(() {
      _isActive = true;
      _scanned = false;
      _hint = "🔍 Сканирование…";
    });
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

void _onDetect(BarcodeCapture cap) {
  if (!_isActive || _scanned) return;

  final raw = cap.barcodes.first.rawValue;
  if (raw == null) return;

  try {
    final data = jsonDecode(raw);
    if (data is! Map || !data.containsKey("key_id")) {
      setState(() => _hint = "❌ Неверный QR-код (без key_id)");
      return;
    }

    final id = data["key_id"];
    if (id is! int) {
      setState(() => _hint = "❌ key_id должен быть числом");
      return;
    }

    setState(() {
      _hint = "🔑 Найден ключ";
      _isActive = false;
      _scanned = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmActionScreen(
            cabinetCode: id.toString(),
            action: widget.action,
            userId: widget.userId,
          ),
        ),
      );
    });
  } catch (e) {
    setState(() => _hint = "❌ Невозможно прочитать QR (ошибка формата)");
  }
}


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2E70E8);
    const grey = Color(0xFF6C6C6C);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Сканер – ${widget.action} ключ"),
        backgroundColor: Colors.white,
        foregroundColor: blue,
        elevation: 1,
        actions: [
          IconButton(                       // 🔦 кнопка‑фонарик
            tooltip: _torchOn ? "Выключить фонарик" : "Включить фонарик",
            icon: Icon(
              _torchOn ? Icons.flashlight_off : Icons.flashlight_on,
              color: _torchOn ? Colors.amber : blue,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Нажмите кнопку ниже и наведите камеру на QR‑код ключа.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: grey),
            ),
          ),
          const SizedBox(height: 24),


          /* область сканера */
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: blue, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _hint,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Сканировать"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
