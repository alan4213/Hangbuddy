import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, dynamic>> hangouts = const [
    {"name": "Bella Benson", "age": 28, "distance": "1.3 km away", "views": 33},
    {"name": "Ruby Diaz", "age": 33, "distance": "1.5 km away", "views": 61},
    {"name": "Myley Corbyn", "age": 29, "distance": "2.0 km away", "views": 49},
    {"name": "Tony Z", "age": 25, "distance": "0.8 km away", "views": 87},
    {"name": "Ava Lee", "age": 26, "distance": "1.2 km away", "views": 56},
    {"name": "Liam Knox", "age": 31, "distance": "1.9 km away", "views": 44},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F7),
      appBar: AppBar(
        title: const Text(
          "Users",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF343B5B),
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.notifications_none, color: Colors.white),
          )
        ],
      ),
      body: Column(
        children: [
          // Top row - Create Hangout and stories
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 15),
            child: Row(
              children: [
                _buildCreateHangoutButton(context),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, color: Colors.grey[600]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text("All", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                Text("Online", style: TextStyle(color: Colors.grey)),
                Text("New Daters", style: TextStyle(color: Colors.grey)),
                Text("Liked You", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Hangout grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: GridView.builder(
                itemCount: hangouts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final user = hangouts[index];
                  return _buildHangoutCard(user);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateHangoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/create'),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEF4C5E),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 5),
          const Text(
            "Create",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHangoutCard(Map<String, dynamic> user) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5E3D9B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // Green dot (online)
          const Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 6,
              backgroundColor: Colors.green,
            ),
          ),
          // User info
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${user['name']}, ${user['age']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user['distance'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "${user['views']}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}