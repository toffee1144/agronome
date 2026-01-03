import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';

class AppUser {
  final int id;
  final String username;
  final String nickname;

  const AppUser({
    required this.id,
    required this.username,
    required this.nickname,
  });

  String get displayName => nickname.isNotEmpty ? nickname : username;

  // Untuk baris kecil di bawah nama
  String get displaySub => username.isNotEmpty ? username : displayName;

  static AppUser fromAnyJson(Map<String, dynamic> json) {
    final data = (json["data"] is Map<String, dynamic>)
        ? (json["data"] as Map<String, dynamic>)
        : json;

    int toInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    String toStr(dynamic v, {String fallback = ""}) {
      if (v == null) return fallback;
      return v.toString();
    }

    return AppUser(
      id: toInt(data["id"]),
      username: toStr(data["username"], fallback: "user"),
      nickname: toStr(data["nickname"], fallback: ""),
    );
  }
}

class UsersApi {
  static Future<AppUser?> fetchUser(int userId) async {
    final base = AppConfig.baseUrl;

    final uris = <Uri>[
      Uri.parse("$base/users/$userId"),
      Uri.parse("$base/users?id=$userId"),
      Uri.parse("$base/api/users/$userId"),
      Uri.parse("$base/api/users?id=$userId"),
    ];

    for (final uri in uris) {
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode < 200 || res.statusCode >= 300) continue;

        final body = res.body.trim();
        if (body.isEmpty) continue;

        final decoded = jsonDecode(body);

        if (decoded is Map<String, dynamic>) {
          return AppUser.fromAnyJson(decoded);
        }

        if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
          return AppUser.fromAnyJson(decoded.first as Map<String, dynamic>);
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }
}

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  static const Color _bg = Color(0xFFF6F7F8);
  static const Color _card = Colors.white;
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _divider = Color(0xFFE5E7EB);

  Future<AppUser?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UsersApi.fetchUser(AppConfig.userId);
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 2),
              const Center(
                child: Text(
                  "Settings",
                  style: TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              FutureBuilder<AppUser?>(
                future: _userFuture,
                builder: (context, snap) {
                  final user = snap.data ??
                      const AppUser(
                        id: 0,
                        username: "demo",
                        nickname: "Demo",
                      );

                  return Container(
                    decoration: _cardDeco(),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _SettingsTile(
                decoration: _cardDeco(),
                icon: Icons.language_rounded,
                title: "Language",
                onTap: () => _open(const _LanguagePage()),
              ),
              const SizedBox(height: 12),

              _SettingsTile(
                decoration: _cardDeco(),
                icon: Icons.lock_outline_rounded,
                title: "Change Password",
                onTap: () => _open(const _ChangePasswordPage()),
              ),
              const SizedBox(height: 12),

              _SettingsTile(
                decoration: _cardDeco(),
                icon: Icons.grid_view_rounded,
                title: "Change Theme",
                onTap: () => _open(const _ChangeThemePage()),
              ),
              const SizedBox(height: 12),

              _SettingsTile(
                decoration: _cardDeco(),
                icon: Icons.description_outlined,
                title: "About",
                onTap: () => _open(const _AboutPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final BoxDecoration decoration;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.decoration,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: decoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Icon(icon, size: 22, color: const Color(0xFF111827)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BaseSimplePage extends StatelessWidget {
  final String title;
  const _BaseSimplePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: const SizedBox.shrink(),
    );
  }
}

class _LanguagePage extends StatelessWidget {
  const _LanguagePage();

  @override
  Widget build(BuildContext context) => const _BaseSimplePage(title: "Language");
}

class _ChangePasswordPage extends StatelessWidget {
  const _ChangePasswordPage();

  @override
  Widget build(BuildContext context) => const _BaseSimplePage(title: "Change Password");
}

class _ChangeThemePage extends StatelessWidget {
  const _ChangeThemePage();

  @override
  Widget build(BuildContext context) => const _BaseSimplePage(title: "Change Theme");
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) => const _BaseSimplePage(title: "About");
}
