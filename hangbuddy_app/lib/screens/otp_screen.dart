import 'dart:async';
import 'package:flutter/material.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  int _secondsRemaining = 60;
  Timer? _timer;
  String _otp = "";

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onNumberTap(String value) {
    if (_otp.length < 4) {
      setState(() {
        _otp += value;
      });
      if (_otp.length == 4) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _onDelete() {
    if (_otp.isNotEmpty) {
      setState(() {
        _otp = _otp.substring(0, _otp.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer
            Text(
              "00:${_secondsRemaining.toString().padLeft(2, '0')}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              "Type the verification code\nwe've sent you",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool filled = index < _otp.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 60,
                  width: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filled ? const Color(0xFFEF4C5E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: filled ? const Color(0xFFEF4C5E) : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    filled ? _otp[index] : "",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: filled ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),

            // Numeric keypad
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 70),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index < 9) {
                    return _buildNumberButton((index + 1).toString());
                  } else if (index == 9) {
                    return const SizedBox.shrink(); // empty space
                  } else if (index == 10) {
                    return _buildNumberButton('0');
                  } else {
                    return _buildDeleteButton();
                  }
                },
              ),
            ),

            const SizedBox(height: 10),

            // Send again
            GestureDetector(
              onTap: () {
                startTimer();
              },
              child: const Text(
                "Send again",
                style: TextStyle(
                  color: Color(0xFFEF4C5E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => _onNumberTap(number),
      borderRadius: BorderRadius.circular(50),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDelete,
      borderRadius: BorderRadius.circular(50),
      child: const Center(
        child: Icon(Icons.backspace_outlined, size: 26),
      ),
    );
  }
}