import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KeyTransferRequestScreen extends StatefulWidget {
  final int keyId;
  final int currentUserId;

  const KeyTransferRequestScreen({
    super.key,
    required this.keyId,
    required this.currentUserId,
  });

  @override
  State<KeyTransferRequestScreen> createState() =>
      _KeyTransferRequestScreenState();
}

class _KeyTransferRequestScreenState extends State<KeyTransferRequestScreen> {
  static const blue = Color(0xFF2E70E8);
  static const grey = Color(0xFF6C6C6C);
  static const baseUrl = "http://10.250.0.19:5000";

  Map<String, dynamic>? keyInfo;
  bool loading = true;
  bool sending = false;
  String errorText = "";

  @override
  void initState() {
    super.initState();
    _loadKeyInfo();
  }

  Future<void> _loadKeyInfo() async {
    try {
      final r = await http.get(Uri.parse("$baseUrl/keys"));
      if (r.statusCode == 200) {
        final keys = (jsonDecode(r.body)["keys"] as List);
        keyInfo = keys.firstWhere(
          (k) => k["id"] == widget.keyId,
          orElse: () => null,
        );
        if (keyInfo == null || keyInfo!["status"] == true) {
          errorText = "Ключ свободен или не найден";
        }
      } else {
        errorText = "Ошибка сервера ${r.statusCode}";
      }
    } catch (e) {
      errorText = "Ошибка сети: $e";
    }
    setState(() => loading = false);
  }

  Future<void> _sendRequest() async {
    if (keyInfo == null || sending) return;
    final fromId = keyInfo!["last_user_id"];
    if (fromId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Владелец ключа не определён")),
      );
      return;
    }

    setState(() => sending = true);
    try {
      final r = await http.post(
        Uri.parse("$baseUrl/transfer-request"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "from_user_id": fromId,
          "to_user_id": widget.currentUserId,
          "key_id": widget.keyId,
        }),
      );

      final ok = r.statusCode == 200;
      final mess = ok ? jsonDecode(r.body)["message"] : "Ошибка передачи";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mess)));
      if (ok) Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ошибка сети")));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  /* ─────────── UI ─────────── */

  @override
  Widget build(BuildContext context) {
    final keyName = keyInfo?["key_name"] ?? "—";
    final owner = keyInfo?["last_user"] ?? "Неизвестно";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Передача ключа"),
        backgroundColor: Colors.white,
        foregroundColor: blue,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorText.isNotEmpty
          ? Center(
              child: Text(errorText, style: const TextStyle(color: Colors.red)),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Card(
                  elevation: 4,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          keyName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Сейчас у $owner",
                          style: const TextStyle(fontSize: 16, color: grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: sending ? null : _sendRequest,
                            style: FilledButton.styleFrom(
                              backgroundColor: blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: sending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.sync_alt_rounded,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              sending ? "Отправка…" : "Запросить передачу",
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
