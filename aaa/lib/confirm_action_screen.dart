import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'key_transfer.dart';

class ConfirmActionScreen extends StatefulWidget {
  final String cabinetCode;
  final String action;
  final int userId;

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
  static const baseUrl = "http://10.250.0.19:5000";
  String? keyLabel;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadKeyLabel();
  }

  Future<void> _loadKeyLabel() async {
    final id = int.tryParse(widget.cabinetCode);
    if (id == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final res = await http.get(Uri.parse("$baseUrl/keys"));
      if (res.statusCode == 200) {
        final keys = (jsonDecode(res.body)["keys"] as List);
        final key = keys.firstWhere((k) => k["id"] == id, orElse: () => null);
        if (key != null) keyLabel = key["key_name"];
      }
    } catch (_) {}
    setState(() => loading = false);
  }

  // 🔹 Проверка: есть ли у пользователя этот ключ
  Future<bool> _userHasKey() async {
    try {
      final url = Uri.parse("$baseUrl/my-keys?user_id=${widget.userId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          final keys = data["keys"] as List;
          final hasKey = keys.any((k) => k["id"] == int.parse(widget.cabinetCode));
          return hasKey;
        }
      }
    } catch (e) {
      debugPrint("Ошибка при проверке ключа: $e");
    }
    return false;
  }

  // 🔹 Сдача ключа
  Future<void> _returnKey() async {
    final hasKey = await _userHasKey();
    if (!hasKey) {
      _showErrorDialog("Ключ не найден в списке");
      return;
    }

    final res = await http.post(
      Uri.parse("$baseUrl/request-key"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "key_id": int.parse(widget.cabinetCode),
        "return": true,
      }),
    );
    _showResultDialog(res);
  }

  // 🔹 Получение ключа
  Future<void> _requestKey() async {
    final res = await http.post(
      Uri.parse("$baseUrl/request-key"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "key_id": int.parse(widget.cabinetCode),
      }),
    );
    _showResultDialog(res);
  }

  // 🔹 Диалог ошибки
  void _showErrorDialog(String message) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Row(
    children: [
    Icon(Icons.error, color: Colors.red, size: 28),
    SizedBox(width: 8),
    Text("Ошибка", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
    ],
    ),
    content: Text(
    message,
    style: const TextStyle(fontSize: 16, color: Colors.black87),
    ),
    actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
    actions: [
    SizedBox(
    width: double.infinity,
    child: ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    textStyle: const TextStyle(fontSize: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: () => Navigator.pop(context),
    child: const Text("OK"),
    ),),
    ],
        ),
    );
  }

  // 🔹 Диалог результата
  void _showResultDialog(http.Response res) {
    final ok = res.statusCode == 200;
    final mess = jsonDecode(res.body)["message"] ?? "Ошибка";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.error,
                color: ok ? Colors.green : Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ok ? "Готово" : "Ошибка",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          mess,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, ok);
              },
              child: const Text("OK"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2E70E8);
    const grey = Color(0xFF6C6C6C);
    final id = widget.cabinetCode;

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
    Column(
    children: [
    SizedBox(
    width: double.infinity,
    child: ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    onPressed: () {
    switch (widget.action.toLowerCase()) {
    case "получить":
    _requestKey();
    break;
    case "сдать":
    _returnKey();
    break;
    case "запросить":
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => KeyTransferRequestScreen(
    keyId: int.parse(id),currentUserId: widget.userId,
    ),
    ),
    );
    break;
    }
    },
      child: const Text("Да", style: TextStyle(fontSize: 18)),
    ),
    ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Нет", style: TextStyle(fontSize: 18)),
        ),
      ),
    ],
    ),
    ],
    ),
    ),
    );
  }
}