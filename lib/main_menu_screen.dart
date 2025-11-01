import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'main.dart' show routeObserver;
import 'memory_game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with WidgetsBindingObserver, RouteAware {
  late AudioPlayer _backgroundPlayer;
  bool _isMusicPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundPlayer = AudioPlayer();
    _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _backgroundPlayer.dispose();
    super.dispose();
  }
  
  @override
  void didPush() {
    // Khi push vào MainMenuScreen, phát nhạc
    print('MainMenu: didPush - playing music');
    _playBackgroundMusic();
  }
  
  @override
  void didPopNext() {
    // Khi quay về MainMenuScreen từ màn hình khác, phát nhạc lại
    print('MainMenu: didPopNext - playing music');
    _playBackgroundMusic();
  }
  
  @override
  void didPushNext() {
    // Khi rời MainMenuScreen, tắt nhạc
    print('MainMenu: didPushNext - pausing music');
    _pauseBackgroundMusic();
  }
  
  @override
  void didPop() {
    // Khi pop khỏi MainMenuScreen, tắt nhạc
    print('MainMenu: didPop - pausing music');
    _pauseBackgroundMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isMusicPaused) {
      _resumeBackgroundMusic();
      _isMusicPaused = false;
    }
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _backgroundPlayer.play(AssetSource('music/main_menu.mp3'));
      _isMusicPaused = false;
    } catch (e) {
      print('Error playing main menu music: $e');
    }
  }

  Future<void> _pauseBackgroundMusic() async {
    print('MainMenu: pausing music');
    try {
      await _backgroundPlayer.pause();
      _isMusicPaused = true;
    } catch (e) {
      print('Error pausing main menu music: $e');
    }
  }

  Future<void> _resumeBackgroundMusic() async {
    print('MainMenu: resuming music, _isMusicPaused=$_isMusicPaused');
    try {
      // Luôn phát lại từ đầu thay vì resume để tránh bug
      await _playBackgroundMusic();
    } catch (e) {
      print('Error resuming main menu music: $e');
    }
  }

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
                        builder: (context) => const MemoryGameScreen(
                          assetFolder: 'assets/puzzle/lv1/',
                        ),
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
                        builder: (context) => const MemoryGameScreen(
                          assetFolder: 'assets/puzzle/lv2/',
                        ),
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
                        builder: (context) => const MemoryGameScreen(
                          assetFolder: 'assets/puzzle/lv3/',
                        ),
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
