
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_hangout_screen.dart';
import 'screens/phone_number_screen.dart';
import 'screens/otp_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SignupPage(),
      routes: {
        '/home': (context) => const MainNavigation(),
        '/create': (context) => const CreateHangoutScreen(),
        '/phone': (context) => const PhoneNumberScreen(),
        '/otp': (context) => const OTPScreen(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text('Explore', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Chats', style: TextStyle(fontSize: 24))),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFEF4C5E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Sign up to continue",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Continue with email
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PhoneNumberScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4C5E),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Continue with email",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 15),

                // Use phone number
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PhoneNumberScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4C5E)),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Use phone number",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFEF4C5E),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Divider with text
                Row(
                  children: const [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "or sign up with",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 25),

                // Social login buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(FontAwesomeIcons.facebookF, Colors.blue, () {}),
                    const SizedBox(width: 25),
                    _socialButton(FontAwesomeIcons.google, Colors.red, () {
                      Navigator.pushReplacementNamed(context, '/home');
                    }),
                    const SizedBox(width: 25),
                    _socialButton(FontAwesomeIcons.apple, Colors.black, () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
