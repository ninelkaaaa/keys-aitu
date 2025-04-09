import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Возможные статусы подтверждения
enum ActionStatus { pending, confirmed, cancelled }

/// Модель сообщения
class Message {
  final String title;
  final String room;
  final String time;
  final Color color;
  ActionStatus? actionStatus;

  Message({
    required this.title,
    required this.room,
    required this.time,
    required this.color,
    this.actionStatus,
  });
}

enum MessageFilter { all, received, returned }

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  MessageFilter selectedFilter = MessageFilter.all;

  final List<Message> allMessages = [
    Message(
      title: 'Подтвердить получение ключа от',
      room: 'C1.3.240',
      time: '2m',
      color: Colors.blue,
      actionStatus: ActionStatus.pending,
    ),
    Message(
      title: 'Подтвердить сдачу ключа от',
      room: 'C1.3.240',
      time: '2m',
      color: Colors.green,
      actionStatus: ActionStatus.pending,
    ),
    Message(
      title: 'Вы отменили получение ключа от',
      room: 'C1.3.245',
      time: '40m',
      color: Colors.grey,
      actionStatus: null,
    ),
  ];

  List<Message> get filteredMessages {
    switch (selectedFilter) {
      case MessageFilter.received:
        return allMessages.where((msg) => msg.color == Colors.blue).toList();
      case MessageFilter.returned:
        return allMessages.where((msg) => msg.color == Colors.green).toList();
      case MessageFilter.all:
      default:
        return allMessages;
    }
  }

  Future<void> _showConfirmationBottomSheet(
      BuildContext context, Message message) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E70E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Вы подтвердили ${message.title.replaceFirst("Подтвердить", "").trim()} ${message.room}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E70E8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Хорошо',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
      setState(() {
        selectedFilter = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white, // ✅ делаем статус-бар белым
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Сообщения'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.black),
              onPressed: _showFilterMenu,
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: ListView.builder(
            key: ValueKey(selectedFilter),
            itemCount: filteredMessages.length,
            itemBuilder: (context, index) {
              final msg = filteredMessages[index];
              return MessageCard(
                message: msg,
                onYesPressed: () async {
                  await _showConfirmationBottomSheet(context, msg);
                  setState(() {
                    msg.actionStatus = ActionStatus.confirmed;
                  });
                },
                onCancelPressed: () {
                  setState(() {
                    msg.actionStatus = ActionStatus.cancelled;
                  });
                },
              )
                  .animate()
                  .slideY(begin: 0.2, duration: 300.ms)
                  .fadeIn(duration: 300.ms)
                  .then(delay: (100 * index).ms);
            },
          ),
        ),
      ),
    );
  }
}

class MessageCard extends StatelessWidget {
  final Message message;
  final VoidCallback onYesPressed;
  final VoidCallback onCancelPressed;

  const MessageCard({
    super.key,
    required this.message,
    required this.onYesPressed,
    required this.onCancelPressed,
  });

  String get displayTitle {
    if (message.actionStatus == ActionStatus.confirmed) {
      return message.title.replaceFirst("Подтвердить", "Вы подтвердили");
    } else if (message.actionStatus == ActionStatus.cancelled) {
      return message.title.replaceFirst("Подтвердить", "Вы отменили");
    }
    return message.title;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = (message.actionStatus == ActionStatus.pending)
        ? const Color(0xFFEDF3FF)
        : Colors.white;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: message.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          message.time,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.room,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          if (message.actionStatus == ActionStatus.pending)
            Padding(
              padding: const EdgeInsets.only(left: 60, top: 8),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: onYesPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E70E8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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
                    onPressed: onCancelPressed,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E70E8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Отмена",
                      style:
                          TextStyle(fontSize: 16, color: Color(0xFF2E70E8)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
