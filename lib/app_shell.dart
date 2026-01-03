import 'package:agronome/dashboard_page.dart';
import 'package:agronome/message_chat_page.dart';
import 'package:agronome/profile_settings_page.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const Color _bg = Color(0xFFF6F7F8);
  static const Color _green = Color(0xFF76B947);
  static const Color _inactive = Color(0xFF111827);

  int _index = 0; // start at DASHBOARD

  final _homeKey = GlobalKey<NavigatorState>();
  final _dashboardKey = GlobalKey<NavigatorState>();
  final _messageKey = GlobalKey<NavigatorState>();
  final _profileKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get _currentKey {
    return switch (_index) {
      0 => _homeKey,
      1 => _dashboardKey,
      2 => _messageKey,
      _ => _profileKey,
    };
  }

  Future<bool> _onWillPop() async {
    final nav = _currentKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    if (_index != 1) {
      setState(() => _index = 1);
      return false;
    }
    return true;
  }

  void _onTap(int i) {
    if (i == _index) {
      final nav = _currentKey.currentState;
      nav?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _bg,
        body: IndexedStack(
          index: _index,
          children: [
            _TabNavigator(
              navigatorKey: _homeKey,
              root: const AgronomeHomePage(),
            ),
            _TabNavigator(
              navigatorKey: _dashboardKey,
              root: const DashboardPage(),
            ),
            _TabNavigator(
              navigatorKey: _messageKey,
              root: const MessageChatPage(),
            ),
            _TabNavigator(
              navigatorKey: _profileKey,
              root: const ProfileSettingsPage(),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
              child: BottomNavigationBar(
                currentIndex: _index,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: _green,
                unselectedItemColor: _inactive,
                selectedLabelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                onTap: _onTap,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded, size: 26),
                    label: 'HOME',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_rounded, size: 26),
                    label: 'DASHBOARD',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.near_me_outlined, size: 26),
                    label: 'MESSAGE',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded, size: 26),
                    label: 'PROFILE',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;

  const _TabNavigator({
    required this.navigatorKey,
    required this.root,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      body: SafeArea(
        child: Center(
          child: Text(
            'Home',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _MessagePlaceholder extends StatelessWidget {
  const _MessagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      body: SafeArea(
        child: Center(
          child: Text(
            'Message',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      body: SafeArea(
        child: Center(
          child: Text(
            'Profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
