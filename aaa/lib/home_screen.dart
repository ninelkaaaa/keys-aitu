import 'package:flutter/material.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> keyHistory = [
    {
      'room': 'Аудитория 101',
      'pickupTime': '10:00',
      'returnTime': '12:00',
      'isReturned': true
    },
    {
      'room': 'Аудитория 102',
      'pickupTime': '11:00',
      'returnTime': '',
      'isReturned': false
    },
    {
      'room': 'Аудитория 103',
      'pickupTime': '09:30',
      'returnTime': '10:30',
      'isReturned': true
    },
  ];

  void _openScanner(BuildContext context, String action) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScannerScreen(action: action),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title:
                    const Text('Получить ключ', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _openScanner(context, "получить");
                },
              ),
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Сдать ключ', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _openScanner(context, "сдать");
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Передать ключ другому пользователю',
                    style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _openScanner(context, "передать");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История ключей'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: keyHistory.length,
        itemBuilder: (context, index) {
          final item = keyHistory[index];
          return InkWell(
            onTap: () {
              print("Нажатие на ${item['room']}");
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Номер аудитории: ${item['room']}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Время получения: ${item['pickupTime']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Время сдачи: ${item['returnTime'].isNotEmpty ? item['returnTime'] : "Не сдан"}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: item['isReturned'] ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item['isReturned'] ? 'Сдан' : 'Не сдан',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
