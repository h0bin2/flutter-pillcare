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
                onTap: () {
                  // TODO: 상세 페이지 이동 또는 다른 동작 정의
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(minHeight: 210, maxHeight: 210),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.only(top: 14, bottom: 14, left: 14, right: 14),
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
                              consultation.pillName != null && consultation.pillName!.isNotEmpty
                                  ? consultation.pillName!
                                  : '약 이름을 입력하지 않았습니다',
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
                ),
              );
            },
          );
        },
      ),
    );
  }
} 