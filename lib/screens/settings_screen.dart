import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_info.dart';
import 'alarm_list_screen.dart';
import 'export_medication_screen.dart';
import 'font_theme_settings_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<UserInfo?> _userInfoFuture;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = AuthService.getCurrentUserInfo().then(
      (map) => map != null ? UserInfo.fromJson(map) : null,
    );
  }

  void _refreshUserInfo() {
    setState(() {
      _userInfoFuture = AuthService.getCurrentUserInfo().then(
        (map) => map != null ? UserInfo.fromJson(map) : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
              child: Container(
                width: double.infinity,
                child: FutureBuilder<UserInfo?>(
                    future: _userInfoFuture,
                    builder: (context, snapshot) {
                      final userInfo = snapshot.data;

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        final error = snapshot.error;
                        if (error != null && error.toString().contains('401')) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          });
                          return const SizedBox.shrink();
                        }
                        return Center(
                          child: Text(
                            '에러 발생: $error',
                            style: const TextStyle(color: Colors.red, fontSize: 18),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: (userInfo?.profileImageUrl?.isNotEmpty ?? false)
                                    ? NetworkImage(userInfo!.profileImageUrl!)
                                    : null,
                                child: (userInfo?.profileImageUrl?.isEmpty ?? true)
                                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userInfo?.nickname ?? '로그인이 필요합니다',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NotoSansKR',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD954),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(0, 0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  if (userInfo == null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    );
                                  } else {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => EditProfileScreen()),
                                    );
                                    if (result == true) {
                                      _refreshUserInfo();
                                    }
                                  }
                                },
                                child: Text(
                                  userInfo == null ? '로그인' : '정보수정',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'NotoSansKR',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.cake, color: Color(0xFFFFB300)),
                                      const SizedBox(width: 10),
                                      const Text('나이', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                                      const Spacer(),
                                      Text(userInfo?.age?.toString() ?? '-', style: const TextStyle(fontSize: 18, fontFamily: 'NotoSansKR')),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.smoking_rooms, color: Color(0xFFFFB300)),
                                      const SizedBox(width: 10),
                                      const Text('흡연', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                                      const Spacer(),
                                      Text(userInfo?.isSmoke == null ? '-' : (userInfo!.isSmoke! ? '예' : '아니오'), style: const TextStyle(fontSize: 18, fontFamily: 'NotoSansKR')),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.local_bar, color: Color(0xFFFFB300)),
                                      const SizedBox(width: 10),
                                      const Text('음주', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                                      const Spacer(),
                                      Text(userInfo?.isDrink == null ? '-' : (userInfo!.isDrink! ? '예' : '아니오'), style: const TextStyle(fontSize: 18, fontFamily: 'NotoSansKR')),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.healing, color: Color(0xFFFFB300)),
                                      const SizedBox(width: 10),
                                      const Text('수술내역', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                                      const Spacer(),
                                      Flexible(child: Text(userInfo?.surgery?.isNotEmpty == true ? userInfo!.surgery! : '-', style: const TextStyle(fontSize: 18, fontFamily: 'NotoSansKR'), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },  
                  ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            ListTile(
              leading: const Icon(Icons.notifications, size: 36),
              title: const Text(
                '알림 설정',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansKR',
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlarmListScreen()),
                );
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red, size: 24),
              title: Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontFamily: 'NotoSansKR',
                ),
              ),
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '로그아웃',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontFamily: 'NotoSansKR',
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            '로그아웃 하시겠습니까?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'NotoSansKR'),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontFamily: 'NotoSansKR',
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('로그아웃 중 오류가 발생했습니다: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontFamily: 'NotoSansKR',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
