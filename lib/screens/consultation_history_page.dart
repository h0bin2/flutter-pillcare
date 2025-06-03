import '../models/consultation_info.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'subscription_screen.dart';
import 'pharmacy_detail_screen.dart';
import 'pharmacy_screen.dart';

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
    _futureConsultations = widget.consultationHistoryFuture;
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
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
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
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            DateFormat('yyyy.MM.dd (E)', 'ko').format(consultation.createdAt),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade700,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          if (consultation.status == 'subscribe') {
                            return ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PharmacyDetailScreen(
                                      pharmacy: {
                                        'name': consultation.pharmacyName,
                                        'address': '',
                                        'distance': '',
                                        'latitude': null,
                                        'longitude': null,
                                      },
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFFF3D1),
                                foregroundColor: Colors.black,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                              ),
                              child: Text('정기구독 신청'),
                            );
                          } else if (consultation.status == 'call' || consultation.status == 'call_direct') {
                            return ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('전화 상담요청'),
                                    content: Text('${consultation.pharmacyName}에 전화 상담을 요청하시겠습니까?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // TODO: 전화 상담요청 처리
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('전화 상담이 요청되었습니다.')),
                                          );
                                        },
                                        child: Text('요청'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFE0E0E0),
                                foregroundColor: Colors.black,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                              ),
                              child: Text('전화 상담요청'),
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 