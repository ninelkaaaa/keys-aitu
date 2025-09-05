import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'login_sreen.dart';
import 'scanner_screen.dart';
import 'user_notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String baseUrl = "http://10.250.0.19:5000";
  List<dynamic> myKeys = [];
  bool isLoading = true;
  String errorMessage = '';
  Timer? _autoRefreshTimer;
  Timer? _newNotificationsTimer;
  int newNotificationsCount = 0;
  bool _mounted = true;
  List<dynamic> history = [];
  Timer? _historyTimer;

  @override
  void initState() {
    super.initState();
    _fetchMyKeys();
    _fetchKeyHistory(); // загрузка сразу
    _checkNewNotifications();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchMyKeys(),
    );
    _newNotificationsTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkNewNotifications(),
    );
    _historyTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchKeyHistory(),
    ); // ⏱️ раз в минуту
  }

  @override
  void dispose() {
    _mounted = false;
    _autoRefreshTimer?.cancel();
    _newNotificationsTimer?.cancel();
    _historyTimer?.cancel(); // ❗
    super.dispose();
  }

  Future<void> _fetchMyKeys() async {
    try {
      final url = Uri.parse("$baseUrl/my-keys?user_id=${widget.userId}");
      final response = await http.get(url);

      if (!_mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            myKeys = data['keys'];
            isLoading = false;
            errorMessage = '';
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? "Неизвестная ошибка";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Ошибка сервера: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage = "Ошибка сети: $e";
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchKeyHistory() async {
    try {
      final url = Uri.parse("$baseUrl/key-history");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          setState(() {
            history = data["history"];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _checkNewNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenStr = prefs.getString("last_seen_history_${widget.userId}");
    final lastSeenTime = lastSeenStr != null
        ? DateTime.tryParse(lastSeenStr)
        : null;

    try {
      final url = Uri.parse("$baseUrl/key-history");
      final response = await http.get(url);

      if (response.statusCode == 200 && _mounted) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final history = data['history'] as List<dynamic>;
          final filtered = history
              .where(
                (e) =>
                    e['user_id'] == widget.userId &&
                    lastSeenTime != null &&
                    DateTime.parse(e['timestamp']).isAfter(lastSeenTime),
              )
              .toList();
          setState(() {
            newNotificationsCount = filtered.length;
          });
        }
      }
    } catch (_) {}
  }

  void _openScanner(String action) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScannerScreen(action: action, userId: widget.userId),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(
              icon: Icons.vpn_key,
              iconColor: Colors.indigo,
              text: "Получить ключ",
              onTap: () {
                Navigator.pop(context);
                _openScanner("получить");
              },
            ),
            const Divider(),
            _buildMenuItem(
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              text: "Сдать ключ",
              onTap: () {
                Navigator.pop(context);
                _openScanner("сдать");
              },
            ),
            const Divider(),
            _buildMenuItem(
              icon: Icons.sync_alt,
              iconColor: Colors.deepOrange,
              text: "Передать ключ",
              onTap: () {
                Navigator.pop(context);
                _openScanner("передать");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(text, style: const TextStyle(fontSize: 18)),
      onTap: onTap,
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("user_id");
    if (!_mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Мои ключи"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.menu), onPressed: _showMenu),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationsScreen(userId: widget.userId),
                    ),
                  );
                  _checkNewNotifications();
                },
              ),

              if (newNotificationsCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$newNotificationsCount",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Обновить вручную",
            onPressed: _fetchMyKeys,
          ),
        ],
      ),
      body: Column(
        children: [
          if (isLoading)
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else
            Expanded(child: _buildKeysList()),
        ],
      ),
    );
  }

  Widget _buildKeysList() {
    if (myKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.vpn_key_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Сегодня вы не брали ключи",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Если получите ключ — они появятся здесь.",
              style: TextStyle(fontSize: 16, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: myKeys.length,
      itemBuilder: (context, index) {
        final item = myKeys[index];
        final keyName = item["key_name"] ?? "???";
        final status = item["status"] == true;

        // Найдём последнюю запись выдачи по этому ключу
        final issueRecord = history.firstWhere(
          (h) => h["key_name"] == keyName && h["action"] == "issue",
          orElse: () => null,
        );

        String subtitle = "";
        if (!status && issueRecord != null) {
          final issuedAtStr = issueRecord["timestamp"];
          final issuedAt = DateTime.tryParse(
            issuedAtStr.replaceAllMapped(
              RegExp(r"(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2})"),
              (m) => "${m[3]}-${m[2]}-${m[1]} ${m[4]}:${m[5]}",
            ),
          );

          Duration diff = DateTime.now().difference(issuedAt ?? DateTime.now());
          final days = diff.inDays;
          final hours = diff.inHours % 24;
          final minutes = diff.inMinutes % 60;

          final timeAgo = days > 0
              ? "$days дн. назад"
              : hours > 0
              ? "$hours ч. назад"
              : "$minutes мин. назад";

          subtitle = "Выдан $issuedAtStr ($timeAgo)";
        } else if (status) {
          subtitle = "Доступен";
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                width: 6,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: status ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Text(
                "Ключ: $keyName",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: subtitle.isEmpty
                  ? null
                  : Text(subtitle, style: const TextStyle(fontSize: 16)),
              trailing: CircleAvatar(
                radius: 10,
                backgroundColor: status
                    ? Colors.green
                    : const Color(0xFF7F9FDB),
              ),
            ),
          ),
        );
      },
    );
  }
}
