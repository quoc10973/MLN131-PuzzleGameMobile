import 'package:flutter/material.dart';
import 'memory_game_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5ECD5), Color(0xFFE5D6B9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.extension, size: 60, color: Colors.blue[700]),
                ),
                const SizedBox(height: 20),
                Text(
                  'MEMORY FLIP GAME',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.brown,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chọn cấp độ phía dưới để bắt đầu!',
                  style: TextStyle(color: Colors.brown, fontSize: 18),
                ),
                const SizedBox(height: 40),
                _MenuButton(
                  label: 'Dễ',
                  icon: Icons.baby_changing_station,
                  color: Colors.lightGreenAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MemoryGameScreen(assetFolder: 'assets/puzzle/lv1/'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _MenuButton(
                  label: 'Vừa',
                  icon: Icons.emoji_emotions,
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MemoryGameScreen(assetFolder: 'assets/puzzle/lv2/'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _MenuButton(
                  label: 'Khó',
                  icon: Icons.auto_awesome,
                  color: Colors.pinkAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MemoryGameScreen(assetFolder: 'assets/puzzle/lv3/'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.black, size: 28),
      style: ElevatedButton.styleFrom(
        elevation: 5,
        backgroundColor: color,
        minimumSize: const Size(200, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      label: Text(label, style: const TextStyle(color: Colors.black)),
      onPressed: onTap,
    );
  }
}
