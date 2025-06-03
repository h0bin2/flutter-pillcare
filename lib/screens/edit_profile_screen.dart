import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  int? age;
  bool isSmoker = false;
  bool isDrinker = false;
  bool hasSurgery = false;

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('나이', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
              const SizedBox(height: 8),
              TextField(
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
                style: const TextStyle(fontSize: 18, fontFamily: 'NotoSansKR'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '수술 경험을 입력하세요 (예: 맹장 수술, 2018년 등)',
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
                onChanged: (value) {
                  // 필요시 상태 저장
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
                  onPressed: () {},
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