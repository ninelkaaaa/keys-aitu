import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'key_transfer.dart';

class ConfirmActionScreen extends StatefulWidget {
  final String cabinetCode; // ID из QR
  final String action;      // получить / сдать / передать
  final int    userId;      // текущий пользователь

  const ConfirmActionScreen({
    super.key,
    required this.cabinetCode,
    required this.action,
    required this.userId,
  });

  @override
  State<ConfirmActionScreen> createState() => _ConfirmActionScreenState();
}

class _ConfirmActionScreenState extends State<ConfirmActionScreen> {
  static const baseUrl = "https://backaitu.onrender.com";
  String? keyLabel;                    // C1.3.221
  bool    loading = true;

  @override
  void initState() {
    super.initState();
    _loadKeyLabel();
  }

  Future<void> _loadKeyLabel() async {
    final id = int.tryParse(widget.cabinetCode);
    if (id == null) {
      setState(() { loading = false; });
      return;
    }

    try {
      final res = await http.get(Uri.parse("$baseUrl/keys"));
      if (res.statusCode == 200) {
        final keys = (jsonDecode(res.body)["keys"] as List);
        final key   = keys.firstWhere((k) => k["id"] == id, orElse: () => null);
        if (key != null) keyLabel = key["key_name"];          // C1.3.221
      }
    } catch (_) {}
    setState(() { loading = false; });
  }

  /* ───────── helpers для запросов ───────────────────── */

  Future<void> _returnKey() async {
    final res = await http.post(
      Uri.parse("$baseUrl/return-key"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "key_id" : int.parse(widget.cabinetCode),
      }),
    );
    _showSnack(res);
  }

  Future<void> _requestKey() async {
    final res = await http.post(
      Uri.parse("$baseUrl/request-key"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "key_id" : int.parse(widget.cabinetCode),
      }),
    );
    _showSnack(res);
  }

  void _showSnack(http.Response res) {
    final ok   = res.statusCode == 200;
    final mess = jsonDecode(res.body)["message"] ?? "Ошибка";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mess)));
    Navigator.pop(context, ok);
  }

  /* ───────── UI ─────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2E70E8);
    const grey = Color(0xFF6C6C6C);
    final id   = widget.cabinetCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Подтверждение"),
        backgroundColor: Colors.white,
        foregroundColor: blue,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Вы действительно хотите "
                    "${widget.action.toLowerCase()} ключ "
                    "${keyLabel ?? '(ID $id)'}?",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: grey),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue, foregroundColor: Colors.white),
                        onPressed: () {
                          switch (widget.action.toLowerCase()) {
                            case "получить": _requestKey();  break;
                            case "сдать"   : _returnKey();   break;
                            case "передать":
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KeyTransferRequestScreen(
                                    keyId        : int.parse(id),
                                    currentUserId: widget.userId,
                                  ),
                                ),
                              );
                              break;
                          }
                        },
                        child: const Text("Да"),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Нет"),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
