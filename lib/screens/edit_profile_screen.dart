import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_info.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  int? age;
  bool isSmoker = false;
  bool isDrinker = false;
  String? surgery;

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _surgeryController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userMap = await AuthService.getCurrentUserInfo();
    if (userMap != null) {
      final user = UserInfo.fromJson(userMap);
      setState(() {
        age = user.age;
        isSmoker = user.isSmoke ?? false;
        isDrinker = user.isDrink ?? false;
        surgery = user.surgery;
        _ageController.text = user.age?.toString() ?? '';
        _surgeryController.text = user.surgery ?? '';
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _surgeryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '정보 수정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
            fontFamily: 'NotoSansKR',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('나이', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18, fontFamily: 'NotoSansKR'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '나이를 입력하세요',
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          age = int.tryParse(value);
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('수술 경험', style: TextStyle(fontSize: 26, fontFamily: 'NotoSansKR')),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _surgeryController,
                      style: const TextStyle(fontSize: 18, fontFamily: 'NotoSansKR'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '수술 경험을 입력하세요 (예: 맹장 수술, 2018년 등)',
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          surgery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('흡연 여부', style: TextStyle(fontSize: 26, fontFamily: 'NotoSansKR')),
                        Switch(
                          value: isSmoker,
                          onChanged: (v) => setState(() => isSmoker = v),
                          activeColor: Color(0xFFFFB300),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('음주 여부', style: TextStyle(fontSize: 26, fontFamily: 'NotoSansKR')),
                        Switch(
                          value: isDrinker,
                          onChanged: (v) => setState(() => isDrinker = v),
                          activeColor: Color(0xFFFFB300),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await AuthService.updateUserInfo(
                              age: age,
                              isDrink: isDrinker,
                              isSmoke: isSmoker,
                              surgery: surgery,
                            );
                            if (mounted) Navigator.pop(context, true);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFD954),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                        ),
                        child: const Text('저장'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 