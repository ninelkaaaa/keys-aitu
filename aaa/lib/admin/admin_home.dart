import 'package:flutter/material.dart';
import 'package:aaa/components/search.dart';
import 'message_page.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:aaa/home_screen.dart'; // измени путь под свой проект


class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}



class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _items = [
    {
      "title": "C1.3.240",
      "dateTime": "12.01.2024 13:00",
      "leftBarColor": Colors.grey,
      "dotColor": Colors.red,
    },
    {
      "title": "C1.3.240",
      "dateTime": "12.01.2024 13:00",
      "leftBarColor": Colors.grey,
      "dotColor": Colors.red,
    },
    {
      "title": "C1.3.245",
      "dateTime": "12.01.2024 13:00",
      "leftBarColor": Colors.blue,
      "dotColor": Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Главная",
          style: TextStyle(
            color: Colors.black, 
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      

     body: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Column(
    children: [
      const SearchFilterRow(),
      const SizedBox(height: 16),

      Expanded(
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return InkWell(
              onTap: () => _showCallSheet(context, item["title"]),
              child: _buildItemCard(item),
            );
          },
        ),
      ),

      // 🔵 Кнопка перехода на HomeScreen
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
          icon: const Icon(Icons.arrow_forward),
          label: const Text("Перейти на Главную"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E70E8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ],
  ),
),

      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
          if (newIndex == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessagePage()),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Главная",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.message),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: "Сообщения",
          ),
        ],
      ),
    );
  }


  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      color: Colors.white, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: item["leftBarColor"],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["title"] ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item["dateTime"] ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: item["dotColor"],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}



void _makePhoneCall(String phoneNumber) async {
  final Uri url = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $phoneNumber';
  }
}

void _showCallSheet(BuildContext context, String title) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Учитель: Петров П.П', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _makePhoneCall('+77009998877'),
                icon: const Icon(Icons.phone),
                label: const Text('Позвонить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E70E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
