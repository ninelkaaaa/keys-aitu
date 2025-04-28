import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> userHistory = [];
  List<dynamic> transferRequests = [];
  bool isLoading = false;
  int selectedTab = 0;

  final String baseUrl = "https://backaitu.onrender.com";
@override
void initState() {
  super.initState();
  _saveOpenedTime();
  setState(() => isLoading = true); // показываем лоадер

  Future.wait([
    _fetchHistory(),
    _fetchTransferRequests(),
  ]).then((_) {
    if (mounted) {
      setState(() => isLoading = false); // безопасный вызов
    }
  });
}



  Future<void> _saveOpenedTime() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("last_seen_history_${widget.userId}", DateTime.now().toIso8601String());
  }
Future<void> _fetchHistory() async {
  try {
    final response = await http.get(Uri.parse("$baseUrl/key-history"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final allHistory = data['history'] as List<dynamic>;
      final filtered = allHistory
          .where((e) => e['user_id'] == widget.userId)
          .toList()
        ..sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

      if (!mounted) return; // 🛑 проверка перед setState
      setState(() => userHistory = filtered);
    }
  } catch (_) {
    if (!mounted) return; // 🛑 защита
    setState(() {
      isLoading = false;
    });
  }
}



  Future<void> _fetchTransferRequests() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/pending-transfers"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final requests = data["requests"] as List;
        if (!mounted) return;
        setState(() {
          transferRequests = requests
              .where((r) => r["from_user_id"] == widget.userId)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _handleTransferDecision(int requestId, bool approve) async {
    final url = Uri.parse(
      "$baseUrl/${approve ? "approve-transfer" : "deny-transfer"}",
    );
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"request_id": requestId}),
    );
    final result = jsonDecode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result["message"] ?? "Ответ обработан")),
    );
    _fetchTransferRequests();
    _fetchHistory();
  }

  Widget _buildSegmentedTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(229, 243, 243, 244),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (i) {
          final labels = ["Все", "Запросы", "История"];
          final selected = selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF2E70E8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransferList() {
    if (transferRequests.isEmpty) {
      return const Center(child: Text("Нет активных запросов на передачу"));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: transferRequests.map((item) {
        final keyName = item["key_name"];
        final toUser = item["to_user_name"];
        final requestId = item["id"];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          color: Colors.white,         

          child: ListTile(
            
            title: Text("Пользователь $toUser просит ключ $keyName"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _handleTransferDecision(requestId, true),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _handleTransferDecision(requestId, false),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryList() {
    if (userHistory.isEmpty) {
      return const Center(child: Text("Нет уведомлений"));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: userHistory.map((item) {
        final String action = item["action"];
        final String keyName = item["key_name"];
        final String time = item["timestamp"];
        String message = switch (action) {
          "request" => "Вы запросили ключ $keyName",
          "issue" => "Вам выдан ключ $keyName",
          "return" => "Вы сдали ключ $keyName",
          "transfer" => "Вы передали ключ $keyName",
          "denied" => "Запрос на $keyName отклонен",
          _ => "Неизвестное действие: $action"
        };

        return ListTile(
          leading: const Icon(Icons.notifications, color: Colors.blue),
          title: Text(message),
          subtitle: Text(time),
        );
      }).toList(),
    );
  }

  Widget _buildCombinedView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (transferRequests.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("🔁 Запросы на передачу", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...transferRequests.map((item) {
            final keyName = item["key_name"];
            final toUser = item["to_user_name"];
            final requestId = item["id"];
            return Card(
                                    color: Colors.white,         

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text("Пользователь $toUser просит ключ $keyName"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _handleTransferDecision(requestId, true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _handleTransferDecision(requestId, false),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: 32),
        ],
        const Text("🔔 История", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...userHistory.map((item) {
          final String action = item["action"];
          final String keyName = item["key_name"];
          final String time = item["timestamp"];
          String message = switch (action) {
            "request" => "Вы запросили ключ $keyName",
            "issue" => "Вам выдан ключ $keyName",
            "return" => "Вы сдали ключ $keyName",
            "transfer" => "Вы передали ключ $keyName",
            "denied" => "Запрос на $keyName отклонен",
            _ => "Неизвестное действие: $action"
          };

          return ListTile(
            leading: const Icon(Icons.notifications_none, color: Colors.blue),
            title: Text(message),
            subtitle: Text(time),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent = switch (selectedTab) {
      0 => _buildCombinedView(),
      1 => _buildTransferList(),
      2 => _buildHistoryList(),
      _ => _buildCombinedView(),
    };

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text("Уведомления"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _buildSegmentedTabs(),
          Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : bodyContent),
        ],
      ),
    );
  }
}
