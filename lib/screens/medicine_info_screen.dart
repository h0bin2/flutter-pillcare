import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // http 패키지 제거
// import 'dart:convert'; // jsonDecode 제거
import '../constants.dart'; // ApiConstants 사용을 위해 추가

class MedicineInfoScreen extends StatefulWidget {
  final Map<String, dynamic> pillData; // pillData 맵을 인자로 받도록 재변경

  const MedicineInfoScreen({
    required this.pillData,
    Key? key,
  }) : super(key: key);

  @override
  State<MedicineInfoScreen> createState() => _MedicineInfoScreenState();
}

class _MedicineInfoScreenState extends State<MedicineInfoScreen> {
  int _selectedTab = 0;
  // Map<String, dynamic>? _fetchedPillData; // API로부터 가져온 약 상세 정보 제거
  // bool _isLoading = true; // 로딩 상태 제거
  // String? _errorMessage; // 에러 메시지 제거

  @override
  void initState() {
    super.initState();
    // _fetchPillDetails(); // API 호출 제거
  }

  // Future<void> _fetchPillDetails() async { ... } // API 호출 함수 전체 제거

  // pillData 맵에서 데이터를 추출하는 getter 정의 (이제 fetchedPillData 고려 안 함)
  String get _name => widget.pillData['pill_name'] ?? '정보 없음';
  String get _imagePath {
    final path = widget.pillData['image_path'] as String?;
    String finalPath;
    if (path == null || path.isEmpty) {
      finalPath = 'assets/images/placeholder.png';
    } else if (path.startsWith('http')) {
      finalPath = path;
    } else {
      String cleanedPath = path!;
      if (cleanedPath.startsWith('flutter-back/')) {
        cleanedPath = cleanedPath.substring('flutter-back/'.length); // 'flutter-back/' 제거
      }
      if (cleanedPath.startsWith('/')) {
        finalPath = '${ApiConstants.baseUrl}$cleanedPath';
      } else {
        finalPath = '${ApiConstants.baseUrl}/$cleanedPath';
      }
    }
    print('[MedicineInfoScreen] Final imagePath: $finalPath');
    return finalPath;
  }

  // list 형태의 데이터 파싱
  List<String> _parseList(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    if (data is String && data.isNotEmpty) {
      return [data];
    }
    return ['정보 없음'];
  }

  List<String> get _effects => _parseList(widget.pillData['effect']);
  List<String> get _usage => _parseList(widget.pillData['dosage']);
  List<String> get _cautions => _parseList(widget.pillData['caution']);

  final List<String> tabTitles = ['효과효능', '용법용량', '주의사항'];
  final List<IconData> tabIcons = [
    Icons.medication,
    Icons.science,
    Icons.warning_amber_rounded,
  ];

  List<List<String>> get tabContents => [
    _effects,
    _usage,
    _cautions,
  ];

  @override
  Widget build(BuildContext context) {
    // 로딩 및 에러 상태 UI 제거
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          _name, // widget.pillData에서 가져온 이름
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 1.2,
            fontFamily: 'NotoSansKR',
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 약 이미지
            Container(
              height: 280,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _imagePath.startsWith('assets/')
                    ? Image.asset( // 로컬 에셋인 경우
                        _imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.medication, color: Colors.white, size: 60),
                      )
                    : Image.network( // 네트워크 이미지인 경우
                        _imagePath,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.medication, color: Colors.white, size: 60),
                      ),
              ),
            ),
            // 탭 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (idx) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == idx ? Color(0xFFFFD954) : Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _selectedTab == idx ? Color(0xFFFFD954) : Colors.black26),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedTab = idx;
                      });
                    },
                    child: Column(
                      children: [
                        Icon(tabIcons[idx], size: 44, color: Colors.black, weight: 800),
                        SizedBox(height: 6),
                        Text(
                          tabTitles[idx],
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Colors.black,
                            letterSpacing: 1.1,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 16),
            // 내용 박스
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFFFD954), width: 2),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.30,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tabContents[_selectedTab].isEmpty
                      ? [Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '해당 정보가 없습니다.',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                          ),
                        )]
                      : tabContents[_selectedTab]
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text('• $e', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                              ))
                          .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 