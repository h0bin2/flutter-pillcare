import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'medicine_info_screen.dart';
import 'pharmacy_screen.dart';
import 'settings_screen.dart';
import 'consultation_history_page.dart';
import 'notice_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../services/auth_service.dart';
import '../models/user_info.dart';
import '../models/consultation_info.dart';
import '../services/record_service.dart';
import '../services/search_service.dart';
import '../../main.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with RouteAware {
  late String _currentDate;
  Timer? _timer;
  late Future<UserInfo?> _userInfoFuture;
  Future<List<ConsultationInfo>>? _consultationHistoryFuture;
  bool showSearchBar = false;
  bool _isSearchVisible = false;
  TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = [];
  List<String> filteredSuggestions = [];
  Future<List<Map<String, dynamic>>?>? _recommendFuture;
  Timer? _autocompleteDebounce;
  bool _shouldLoadRecommend = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _autocompleteResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw '전화를 걸 수 없습니다: $phoneNumber';
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _updateDate();
    // 매일 자정에 날짜 업데이트
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (now.hour == 0 && now.minute == 0) {
        _updateDate();
      }
    });

    _userInfoFuture = _loadUserInfo();
    _userInfoFuture.then((userInfo) {
      if (userInfo != null && mounted) {
        if (userInfo.id != null) {
          setState(() {
            _consultationHistoryFuture = AuthService.getConsultationHistory(userInfo.id!);
            _recommendFuture = null;
            _shouldLoadRecommend = false;
          });
        } else {
          printError("initState: UserInfo에 id 필드가 없습니다. 상담 내역을 로드할 수 없습니다.");
          setState(() {
            _consultationHistoryFuture = Future.value([]);
            _recommendFuture = null;
            _shouldLoadRecommend = false;
          });
        }
      } else if (mounted) {
        printError("initState: 사용자 정보를 가져오지 못했습니다.");
        setState(() {
          _consultationHistoryFuture = Future.value([]);
          _recommendFuture = null;
          _shouldLoadRecommend = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        printError("initState: 사용자 정보 로드 중 오류: $error");
        setState(() {
          _consultationHistoryFuture = Future.error(error);
          _recommendFuture = null;
          _shouldLoadRecommend = false;
        });
      }
    });
  }

  Future<UserInfo?> _loadUserInfo() async {
    try {
      final userInfoMap = await AuthService.getCurrentUserInfo();
      if (userInfoMap != null) {
        return UserInfo.fromJson(userInfoMap);
      }
      return null;
    } catch (e) {
      print("Error in _loadUserInfo: $e");
      return null;
    }
  }

  void printError(String message) {
    if (kDebugMode) {
      print('\x1B[31m$message\x1B[0m');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    // 메인화면으로 다시 돌아올 때마다 상담 내역 새로고침
    _userInfoFuture.then((userInfo) {
      if (userInfo != null && mounted) {
        if (userInfo.id != null) {
          setState(() {
            _consultationHistoryFuture = AuthService.getConsultationHistory(userInfo.id!);
            _recommendFuture = RecordService.getRecommendations(); // 캐시 우선 사용
          });
        }
      }
    });
  }

  void _updateDate() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy. MM. dd');
    final weekDay = _getWeekDay(now.weekday);
    setState(() {
      _currentDate = '${formatter.format(now)} ($weekDay)';
    });
  }

  String _getWeekDay(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  // 전화 옵션 모달 함수 추가
  void _showPhoneOptions(BuildContext context, String phoneNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 전화상담요청 버튼
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size.fromHeight(48),
                  alignment: Alignment.centerLeft,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.phone, color: Colors.black, size: 32),
                label: Text(
                  '전화상담요청',
                  style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                ),
                onPressed: () {
                  // TODO: 전화상담요청 로직
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              // 전화걸기 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size.fromHeight(48),
                  alignment: Alignment.centerLeft,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _makePhoneCall(phoneNumber);
                },
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.black, size: 32),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(phoneNumber, style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                        Text('전화걸기', style: TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'NotoSansKR')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NoticeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                _isSearchVisible = true;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 160,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentDate,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: constraints.maxHeight * 0.1,
                                fontFamily: 'NotoSansKR',
                              ),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.03),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FutureBuilder<UserInfo?>(
                                    future: _userInfoFuture,
                                    builder: (context, snapshot) {
                                      Widget nameWidget;
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        nameWidget = SizedBox(
                                            width: constraints.maxHeight * 0.3,
                                            height: constraints.maxHeight * 0.3,
                                            child: CircularProgressIndicator(strokeWidth: 2));
                                      } else if (snapshot.hasError) {
                                        printError("Error loading user info in FutureBuilder: \\${snapshot.error}");
                                        nameWidget = Text('사용자 로딩 오류', style: TextStyle(fontSize: constraints.maxHeight * 0.3, color: Colors.red, fontFamily: 'NotoSansKR'));
                                      } else if (snapshot.hasData && snapshot.data != null) {
                                        final userInfo = snapshot.data!;
                                        nameWidget = Text(
                                          userInfo.nickname ?? '최순자',
                                          style: TextStyle(
                                            fontSize: constraints.maxHeight * 0.3,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF000080),
                                            fontFamily: 'NotoSansKR',
                                          ),
                                        );
                                      } else {
                                        nameWidget = Text('방문자', style: TextStyle(fontSize: constraints.maxHeight * 0.3, fontWeight: FontWeight.w900, color: Color(0xFF000080), fontFamily: 'NotoSansKR'));
                                      }
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              nameWidget,
                                              Text(
                                                '님',
                                                style: TextStyle(
                                                  fontSize: constraints.maxHeight * 0.2,
                                                  color: Colors.black,
                                                  fontFamily: 'NotoSansKR',
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: constraints.maxHeight * 0.03),
                                          FutureBuilder<List<Map<String, dynamic>>?>(
                                            future: RecordService.getRecords(),
                                            builder: (context, snapshot) {
                                              String message = '약 드셨나요?';
                                              if (snapshot.hasData && snapshot.data != null && _hasTodayRecord(snapshot.data!)) {
                                                message = '약 복용을 했어요';
                                              }
                                              return Text(
                                                message,
                                                style: TextStyle(
                                                  fontSize: constraints.maxHeight * 0.2,
                                                  color: Colors.black,
                                                  fontFamily: 'NotoSansKR',
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  Spacer(),
                                  Container(
                                    width: constraints.maxHeight * 0.8,
                                    height: constraints.maxHeight * 0.8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 6,
                                      ),
                                    ),
                                    child: FutureBuilder<UserInfo?>(
                                      future: _userInfoFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data?.profileImageUrl != null && snapshot.data!.profileImageUrl!.isNotEmpty) {
                                          return CircleAvatar(
                                            backgroundImage: NetworkImage(snapshot.data!.profileImageUrl!),
                                            backgroundColor: Colors.transparent,
                                            radius: (constraints.maxHeight * 0.8) / 2,
                                          );
                                        } else {
                                          return Center(
                                            child: Icon(Icons.local_florist, color: Color(0xFF000080), size: 36),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  RecommendSection(future: _recommendFuture),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConsultationHistoryPage(
                                consultationHistoryFuture: _consultationHistoryFuture,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          '최근 상담 내역 >',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            fontFamily: 'NotoSansKR',                        decorationColor: Color(0xFFFFD954),
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  FutureBuilder<List<ConsultationInfo>>(
                    future: _consultationHistoryFuture,
                    builder: (context, snapshot) {
                      List<ConsultationInfo> consultations = [];
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        printError("Error loading consultation history: \\${snapshot.error}");
                        return Center(child: Text('상담 내역을 불러오는 중 오류가 발생했습니다.', style: TextStyle(color: Colors.red, fontFamily: 'NotoSansKR')));
                      } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        consultations = snapshot.data!.isNotEmpty
                            ? snapshot.data!.sublist(0, 1)
                            : [];
                        if (!_shouldLoadRecommend) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() {
                                  _recommendFuture = RecordService.getRecommendations();
                                  _shouldLoadRecommend = true;
                                });
                              });
                            }
                      }
                      if (consultations.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 70, horizontal: 20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '최근 상담 내역이 없습니다.',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'NotoSansKR'),
                            ),
                          ),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade500),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: consultations.length,
                          itemBuilder: (context, index) {
                            final consultation = consultations[index];
                            return Container(
                              constraints: BoxConstraints(minHeight: 210, maxHeight: 210),
                              padding: EdgeInsets.only(
                                top: 14,
                                bottom: index == consultations.length - 1 ? 14 : 10,
                                left: 14,
                                right: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          consultation.pharmacyName,
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'NotoSansKR',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        consultation.formattedCreatedAt,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade700,
                                          fontFamily: 'NotoSansKR',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  if (consultation.pillName != null && consultation.pillName!.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      margin: EdgeInsets.only(bottom: 6),
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFF3D1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.medication, color: Color(0xFFFFB300), size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            '약 이름',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFFFB300),
                                              fontFamily: 'NotoSansKR',
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            consultation.pillName!,
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontFamily: 'NotoSansKR',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    width: double.infinity,
                                    constraints: BoxConstraints(minHeight: 90, maxHeight: 90),
                                    margin: EdgeInsets.only(top: 0),
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.description, color: Colors.grey, size: 18),
                                            SizedBox(width: 6),
                                            Text(
                                              '증상',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey,
                                                fontFamily: 'NotoSansKR',
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          consultation.history,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                            fontFamily: 'NotoSansKR',
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade300,
                            indent: 20,
                            endIndent: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: Color(0xFFFFD954),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 105,
                            height: 110,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.black,
                                  size: 52,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '기록',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoSansKR',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Color(0xFFFFD954),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CameraScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 105,
                            height: 110,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.black,
                                  size: 52,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '카메라',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoSansKR',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Color(0xFFFFD954),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PharmacyScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 105,
                            height: 110,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.black,
                                  size: 52,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '약국',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoSansKR',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isSearchVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearchVisible = false;
                    _searchController.clear();
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.18),
                ),
              ),
            ),
          if (_isSearchVisible)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // 검색창
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: _handleSearch,
                          decoration: InputDecoration(
                            hintText: '약 이름을 검색하세요',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        if (_isSearching)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        if (_autocompleteResults.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            constraints: BoxConstraints(maxHeight: 300),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _autocompleteResults.length,
                              itemBuilder: (context, index) {
                                final pill = _autocompleteResults[index];
                                return ListTile(
                                  leading: pill['image_path'] != null
                                      ? Image.network(
                                          _getImageUrl(pill['image_path']),
                                          width: 40,
                                          height: 40,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(Icons.medication, size: 40),
                                        )
                                      : Icon(Icons.medication, size: 40),
                                  title: Text(pill['drug_name'] ?? '이름 없음'),
                                  onTap: () => _onAutocompleteItemTap(pill),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.yellow[700],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 40,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
      ],
    );
  }

  void _addToRecentSearches(String search) {
    if (!recentSearches.contains(search)) {
      recentSearches.add(search);
    }
    filteredSuggestions = recentSearches.where((s) => s.toLowerCase().contains(search.toLowerCase())).toList();
  }

  // 오늘 날짜에 기록이 있는지 검사하는 함수
  bool _hasTodayRecord(List<Map<String, dynamic>> records) {
    final now = DateTime.now();
    return records.any((record) {
      if (record['created_at'] != null && record['created_at'] is String) {
        final recordDate = DateTime.parse(record['created_at']).toLocal();
        return recordDate.year == now.year &&
            recordDate.month == now.month &&
            recordDate.day == now.day;
      }
      return false;
    });
  }

  Future<void> _searchPills(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await SearchService.search(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _getAutocomplete(String query) async {
    if (query.isEmpty) {
      setState(() {
        _autocompleteResults = [];
      });
      return;
    }

    try {
      final results = await SearchService.autocomplete(query);
      if (mounted) {
        setState(() {
          _autocompleteResults = results;
        });
      }
    } catch (e) {
      print('자동완성 오류: $e');
      if (mounted) {
        setState(() {
          _autocompleteResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('자동완성 서비스에 연결할 수 없습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.isEmpty) {
      setState(() {
        _autocompleteResults = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _getAutocomplete(query);
    });
  }

  void _onAutocompleteItemTap(Map<String, dynamic> pill) {
    setState(() {
      _isSearchVisible = false;
      _searchController.clear();
    });
    _searchPills(pill['drug_name']).then((_) {
      if (_searchResults.isNotEmpty) {
        _navigateToMedicineInfo(_searchResults[0]);
      }
    });
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null) return 'assets/omega3.png';
    if (imagePath.startsWith('http')) return imagePath;
    String cleanPath = imagePath.replaceAll('flutter-back/', '');
    return 'http://1.244.99.89:5000/$cleanPath';
  }

  void _navigateToMedicineInfo(Map<String, dynamic> pillData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineInfoScreen(
          pillData: {
            'pill_name': pillData['drug_name'] ?? '알 수 없는 약',
            'image_path': _getImageUrl(pillData['image_path']),
            'effect': pillData['effect'] != null ? [pillData['effect'].toString()] : [],
            'dosage': pillData['dosage'] != null ? [pillData['dosage'].toString()] : [],
            'caution': pillData['caution'] != null ? [pillData['caution'].toString()] : [],
          },
        ),
      ),
    );
  }
}

// RecommendSection을 StatefulWidget으로 변경
class RecommendSection extends StatefulWidget {
  final Future<List<Map<String, dynamic>>?>? future;
  const RecommendSection({Key? key, required this.future}) : super(key: key);
  @override
  State<RecommendSection> createState() => _RecommendSectionState();
}

class _RecommendSectionState extends State<RecommendSection> {
  Future<List<Map<String, dynamic>>?>? _future;
  bool _forceNetworkTried = false;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
    if (_future == null) {
      // 상담내역이 없어서 future가 null이면 강제로 추천 API 요청
      // (이제는 main_screen.dart에서 타이밍 제어하므로 여기선 필요 없음)
    }
  }

  @override
  void didUpdateWidget(covariant RecommendSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.future != oldWidget.future) {
      setState(() {
        _future = widget.future;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text('추천', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black, fontFamily: 'NotoSansKR')),
        ),
        Container(
          width: double.infinity,
          height: 140,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Color(0xFFFFD954),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _future == null
              ? Center(child: CircularProgressIndicator())
              : FutureBuilder<List<Map<String, dynamic>>?>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('추천을 불러오는 중 오류', style: TextStyle(fontFamily: 'NotoSansKR', color: Colors.red)));
                    } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                      if (!_forceNetworkTried) {
                        _forceNetworkTried = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _future = RecordService.getRecommendations(forceNetwork: true);
                          });
                        });
                      }
                      return Center(child: Text('추천 데이터가 없습니다.', style: TextStyle(fontFamily: 'NotoSansKR', color: Colors.grey)));
                    } else {
                      final rec = snapshot.data![0];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          print('[MainScreen] Recommendation data: $rec');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicineInfoScreen(
                                pillData: {
                                  'pill_name': rec['name'] ?? '추천 영양제',
                                  'image_path': rec['image_path'] ?? 'assets/omega3.png',
                                  'effect': (rec['effects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                                  'dosage': (rec['usage'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                                  'caution': (rec['cautions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                                },
                              ),
                            ),
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.medication,
                                    color: Colors.black54,
                                    size: 30,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  rec['name'] ?? '추천 영양제',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    fontFamily: 'NotoSansKR',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            SizedBox(width: 20),
                            Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: AutoSizeText(
                                    (rec['reason'] != null && rec['reason'].toString().isNotEmpty)
                                      ? rec['reason'].toString()
                                      : '추천 영양제의 효과를 확인해보세요.',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      height: 1.4,
                                      fontFamily: 'NotoSansKR',
                                    ),
                                    textAlign: TextAlign.left,
                                    maxLines: 10,
                                    minFontSize: 6,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }
}