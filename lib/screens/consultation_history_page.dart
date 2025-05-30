import '../models/consultation_info.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConsultationHistoryPage extends StatefulWidget {
  final Future<List<ConsultationInfo>>? consultationHistoryFuture;
  const ConsultationHistoryPage({Key? key, this.consultationHistoryFuture}) : super(key: key);

  @override
  State<ConsultationHistoryPage> createState() => _ConsultationHistoryPageState();
}

class _ConsultationHistoryPageState extends State<ConsultationHistoryPage> {
  Future<List<ConsultationInfo>>? _futureConsultations;

  @override
  void initState() {
    super.initState();
    // 전달된 Future가 있으면 사용, 없으면 AuthService에서 직접 불러오기
    if (widget.consultationHistoryFuture != null) {
      _futureConsultations = widget.consultationHistoryFuture;
    } else {
      // userId를 AuthService에서 가져와서 호출 (실제 앱 구조에 맞게 수정 필요)
      AuthService.getCurrentUserInfo().then((userInfoMap) {
        if (userInfoMap != null && userInfoMap['id'] != null) {
          setState(() {
            _futureConsultations = AuthService.getConsultationHistory(userInfoMap['id']);
          });
        } else {
          if (kDebugMode) print('[ConsultationHistoryPage] 사용자 정보 없음');
          setState(() {
            _futureConsultations = Future.value([]);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('상담 내역', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'NotoSansKR')),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ConsultationInfo>>(
        future: _futureConsultations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('상담 내역을 불러오는 중 오류가 발생했습니다.', style: TextStyle(color: Colors.red, fontFamily: 'NotoSansKR')));
          }
          final consultations = snapshot.data ?? [];
          if (consultations.isEmpty) {
            return Center(child: Text('최근 상담 내역이 없습니다.', style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontFamily: 'NotoSansKR')));
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: consultations.length,
            itemBuilder: (context, index) {
              final consultation = consultations[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          consultation.pharmacyName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          DateFormat('yyyy.MM.dd (E)', 'ko').format(consultation.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      consultation.history,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'NotoSansKR',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 