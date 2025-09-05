import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ActionStatus { pending, confirmed, cancelled }

class PendingRequest {
  final int historyId;
  final String title;
  final String room;
  final String time;
  final bool isReceive;
  ActionStatus status;

  PendingRequest({
    required this.historyId,
    required this.title,
    required this.room,
    required this.time,
    required this.isReceive,
    this.status = ActionStatus.pending,
  });
}

//
enum MessageFilter { all, received, returned }

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  MessageFilter selectedFilter = MessageFilter.all;

  final String baseUrl = "http://10.250.0.19:5000";

  List<PendingRequest> allRequests = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("$baseUrl/pending-requests");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List reqs = data['requests'];
          final temp = reqs.map<PendingRequest>((item) {
            final hId = item['history_id'] as int;
            final kName = item['key_name'] as String? ?? '???';
            final user = item['user_name'] as String? ?? '???';
            final ts = item['timestamp'] as String? ?? '...';
            final act = item['action'] as String? ?? 'request';

            final isReceive = act == 'request';
            final title = isReceive
                ? "Подтвердить получение ключа от $user?"
                : "Подтвердить сдачу ключа от $user?";

            return PendingRequest(
              historyId: hId,
              title: title,
              room: kName,
              time: ts,
              isReceive: isReceive,
            );
          }).toList();

          setState(() {
            allRequests = temp;
            errorMessage = '';
          });
        } else {
          setState(
            () => errorMessage = data['message'] ?? "Неизвестная ошибка",
          );
        }
      } else {
        setState(() => errorMessage = "Ошибка сервера: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => errorMessage = "Сетевая ошибка: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _approveRequest(int historyId) async {
    final url = Uri.parse("$baseUrl/approve-request");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"history_id": historyId}),
    );
    if (response.statusCode == 200) {
      // success => уберем из списка
      setState(() {
        allRequests.removeWhere((r) => r.historyId == historyId);
      });
    } else {
      final err = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err["message"] ?? "Ошибка одобрения")),
      );
    }
  }

  Future<void> _denyRequest(int historyId) async {
    final url = Uri.parse("$baseUrl/deny-request");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"history_id": historyId}),
    );
    if (response.statusCode == 200) {
      setState(() {
        allRequests.removeWhere((r) => r.historyId == historyId);
      });
    } else {
      final err = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err["message"] ?? "Ошибка отклонения")),
      );
    }
  }

  List<PendingRequest> get filteredMessages {
    switch (selectedFilter) {
      case MessageFilter.received:
        // Показывать только "На получение"
        return allRequests.where((msg) => msg.isReceive).toList();
      case MessageFilter.returned:
        // Показывать только "На сдачу"
        return allRequests.where((msg) => !msg.isReceive).toList();
      case MessageFilter.all:
        return allRequests;
    }
  }

  void _showFilterMenu() async {
    final result = await showModalBottomSheet<MessageFilter>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: MessageFilter.values.map((filter) {
              return ListTile(
                title: Text(
                  filter == MessageFilter.all
                      ? 'Все'
                      : filter == MessageFilter.returned
                      ? 'На сдачу'
                      : 'На получение',
                ),
                trailing: selectedFilter == filter
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => Navigator.pop(context, filter),
              );
            }).toList(),
          ),
        );
      },
    );

    if (result != null) {
      setState(() => selectedFilter = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Уведомления'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showFilterMenu,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchPendingRequests,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : filteredMessages.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Нет новых запросов",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "Все запросы на получение и сдачу ключей будут отображаться здесь. "
                      "Как только появятся новые — вы увидите их в этом списке.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: ListView.builder(
                key: ValueKey(selectedFilter),
                itemCount: filteredMessages.length,
                itemBuilder: (context, index) {
                  final req = filteredMessages[index];
                  return _buildRequestCard(req);
                },
              ),
            ),
    );
  }

  Widget _buildRequestCard(PendingRequest req) {
    return Container(
      color: req.status == ActionStatus.pending
          ? const Color(0xFFEDF3FF)
          : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: req.isReceive ? Colors.blue : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.title, // "Подтвердить получение ключа от Петров П..."
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      req.room, // "C1.3.240"
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Text(
                req.time,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(width: 16),
            ],
          ),
          if (req.status == ActionStatus.pending)
            Padding(
              padding: const EdgeInsets.only(left: 60, top: 8),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await _approveRequest(req.historyId);
                      setState(() => req.status = ActionStatus.confirmed);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E70E8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Да",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await _denyRequest(req.historyId);
                      setState(() => req.status = ActionStatus.cancelled);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E70E8)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Отмена",
                      style: TextStyle(fontSize: 16, color: Color(0xFF2E70E8)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
