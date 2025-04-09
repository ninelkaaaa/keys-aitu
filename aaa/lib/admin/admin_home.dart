import 'package:flutter/material.dart';
import 'package:aaa/components/search.dart';
import 'message_page.dart'; 

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
      // Force the entire page to have a white background.
      backgroundColor: Colors.white,
      
      appBar: AppBar(
        backgroundColor: Colors.white, // AppBar as white
        elevation: 0, // Remove default shadow if needed.
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Главная",
          style: TextStyle(
            color: Colors.black, // Title text in black for contrast.
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Make sure SearchFilterRow is designed with a white background.
            const SearchFilterRow(), 
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _buildItemCard(item);
                },
              ),
            ),
          ],
        ),
      ),
      
      // Set bottom navigation bar background to white.
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
          // Navigate to MessagePage if the "Сообщения" item is tapped.
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

  /// Builds a card for each item in the list.
  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      color: Colors.white, // Ensures that the card background is white.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Left colored stripe.
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
            // Text content.
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
            // Right dot indicator.
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
