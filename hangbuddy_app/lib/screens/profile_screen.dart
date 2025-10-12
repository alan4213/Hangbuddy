import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFEF4C5E),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hangout Enthusiast',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statItem('Hangouts', '24'),
                      _statItem('Friends', '156'),
                      _statItem('Rating', '4.8'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu items
            _menuSection([
              _menuItem(Icons.event, 'My Hangouts', () {}),
              _menuItem(Icons.favorite, 'Favorites', () {}),
              _menuItem(Icons.history, 'History', () {}),
            ]),

            const SizedBox(height: 20),

            _menuSection([
              _menuItem(Icons.notifications, 'Notifications', () {}),
              _menuItem(Icons.privacy_tip, 'Privacy', () {}),
              _menuItem(Icons.help, 'Help & Support', () {}),
            ]),

            const SizedBox(height: 20),

            _menuSection([
              _menuItem(Icons.logout, 'Logout', () {}, isDestructive: true),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEF4C5E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _menuSection(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}