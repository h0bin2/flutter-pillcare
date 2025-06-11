import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({Key? key}) : super(key: key);

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  List<Map<String, dynamic>> _alarms = [];
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getString('alarms');
    if (alarmsJson != null) {
      setState(() {
        _alarms = List<Map<String, dynamic>>.from(json.decode(alarmsJson));
      });
    }
  }

  Future<void> _deleteAlarm(int id) async {
    // 해당 알림의 scheduledNotificationIds를 찾아서 모두 취소합니다.
    final alarmToDelete = _alarms.firstWhere((alarm) => alarm['id'] == id, orElse: () => {});
    if (alarmToDelete.isNotEmpty && alarmToDelete.containsKey('scheduledNotificationIds')) {
      List<int> scheduledIds = List<int>.from(alarmToDelete['scheduledNotificationIds']);
      for (int scheduledId in scheduledIds) {
        await _notifications.cancel(scheduledId);
      }
    } else {
      // 이전 버전의 알림 데이터 호환성 (단일 ID만 있는 경우)
      await _notifications.cancel(id);
    }

    setState(() {
      _alarms.removeWhere((alarm) => alarm['id'] == id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarms', json.encode(_alarms));
  }

  Future<void> _updateAlarm(Map<String, dynamic> alarm, DateTime newTime, bool isDailyRepeat, List<bool> selectedDays) async {
    // 기존 알림의 모든 스케줄된 ID를 취소합니다.
    if (alarm.containsKey('scheduledNotificationIds')) {
      List<int> oldScheduledIds = List<int>.from(alarm['scheduledNotificationIds']);
      for (int oldId in oldScheduledIds) {
        await _notifications.cancel(oldId);
      }
    } else {
      // 이전 버전의 알림 데이터 호환성
      await _notifications.cancel(alarm['id']);
    }

    // 새로운 알림 ID 생성 (base ID)
    final int newBaseId = newTime.millisecondsSinceEpoch ~/ 1000;

    // 새로운 알림 스케줄링 및 ID 저장
    List<int> newScheduledIds = [];

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'pillcare_notification_channel',
      'PillCare 알림',
      channelDescription: '약 복용 시간을 알려줍니다.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iosPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    final String pillName = alarm['pillName'] ?? '이름 모름';
    final String title = '약 복용 시간 알림';
    final String body = '${pillName} 복용 시간입니다!';
    final String payload = jsonEncode(alarm['pillData']);

    // 한국 시간으로 변환
    final seoul = tz.getLocation('Asia/Seoul');
    final scheduledKST = tz.TZDateTime.from(newTime, seoul);

    if (isDailyRepeat) {
      await _notifications.zonedSchedule(
        newBaseId,
        title,
        body,
        scheduledKST,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      newScheduledIds.add(newBaseId);
    } else {
      for (int i = 0; i < 7; i++) {
        if (selectedDays[i]) {
          final dayOffset = (i + 1) % 7; // 월요일이 1, 일요일이 7
          final notificationTime = scheduledKST.add(Duration(days: dayOffset));
          
          final int notificationIdForDay = newBaseId + i;
          await _notifications.zonedSchedule(
            notificationIdForDay,
            title,
            body,
            notificationTime,
            platformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
          newScheduledIds.add(notificationIdForDay);
        }
      }
    }

    // SharedPreferences 업데이트
    setState(() {
      final index = _alarms.indexWhere((a) => a['id'] == alarm['id']);
      if (index != -1) {
        _alarms[index] = {
          ...alarm,
          'id': newBaseId, // 기본 ID 업데이트
          'scheduledNotificationIds': newScheduledIds, // 스케줄된 모든 ID 업데이트
          'time': scheduledKST.toIso8601String(),
          'isDailyRepeat': isDailyRepeat,
          'selectedDays': selectedDays,
        };
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarms', json.encode(_alarms));
  }

  void _showAlarmEditDialog(Map<String, dynamic> alarm) {
    final List<String> ampm = ['오전', '오후'];
    final List<int> hours = List.generate(12, (i) => i + 1);
    final List<int> minutes = List.generate(12, (i) => i * 5);
    
    // 현재 알림 시간 가져오기
    final currentTime = DateTime.parse(alarm['time']);
    int selectedAmpm = currentTime.hour < 12 ? 0 : 1;
    int selectedHour = currentTime.hour % 12;
    if (selectedHour == 0) selectedHour = 12;
    int selectedMinute = (currentTime.minute ~/ 5) * 5;

    // 현재 반복 설정 가져오기
    bool isDailyRepeat = alarm['isDailyRepeat'] ?? false;
    List<bool> selectedDays = alarm['selectedDays'] != null 
        ? List<bool>.from(alarm['selectedDays'])
        : List.generate(7, (index) => false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[300],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    '알림 수정',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 시간 선택
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 오전/오후
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: selectedAmpm),
                            itemExtent: 40,
                            onSelectedItemChanged: (idx) {
                              setState(() => selectedAmpm = idx);
                            },
                            children: ampm.map((e) => Center(
                              child: Text(
                                e,
                                style: TextStyle(
                                  fontSize: selectedAmpm == ampm.indexOf(e) ? 24 : 20,
                                  fontWeight: selectedAmpm == ampm.indexOf(e) ? FontWeight.bold : FontWeight.normal,
                                  color: selectedAmpm == ampm.indexOf(e) ? Colors.black : Colors.grey,
                                  fontFamily: 'NotoSansKR',
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                        // 시
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: selectedHour-1),
                            itemExtent: 40,
                            onSelectedItemChanged: (idx) {
                              setState(() => selectedHour = hours[idx]);
                            },
                            children: hours.map((h) => Center(
                              child: Text(
                                '$h',
                                style: TextStyle(
                                  fontSize: selectedHour == h ? 32 : 24,
                                  fontWeight: selectedHour == h ? FontWeight.bold : FontWeight.normal,
                                  color: selectedHour == h ? Colors.black : Colors.grey,
                                  fontFamily: 'NotoSansKR',
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                        // :
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(':', style: TextStyle(fontSize: 32, color: Colors.grey[400], fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                        ),
                        // 분
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: selectedMinute~/5),
                            itemExtent: 40,
                            onSelectedItemChanged: (idx) {
                              setState(() => selectedMinute = minutes[idx]);
                            },
                            children: minutes.map((m) => Center(
                              child: Text(
                                m.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: selectedMinute == m ? 32 : 24,
                                  fontWeight: selectedMinute == m ? FontWeight.bold : FontWeight.normal,
                                  color: selectedMinute == m ? Colors.black : Colors.grey,
                                  fontFamily: 'NotoSansKR',
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 반복 설정
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 매일 반복 옵션
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '매일 반복',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansKR',
                                ),
                              ),
                              Switch(
                                value: isDailyRepeat,
                                onChanged: (value) {
                                  setState(() {
                                    isDailyRepeat = value;
                                    if (value) {
                                      selectedDays = List.generate(7, (index) => false);
                                    }
                                  });
                                },
                                activeColor: Color(0xFFFFD954),
                              ),
                            ],
                          ),
                          if (!isDailyRepeat) ...[
                            SizedBox(height: 12),
                            Text(
                              '요일 선택',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NotoSansKR',
                              ),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: List.generate(7, (index) {
                                  final days = ['월', '화', '수', '목', '금', '토', '일'];
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        days[index],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'NotoSansKR',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedDays[index] = !selectedDays[index];
                                          });
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selectedDays[index] ? Color(0xFFFFD954) : Colors.grey[200],
                                          ),
                                          child: selectedDays[index]
                                              ? Icon(Icons.check, color: Colors.black, size: 16)
                                              : null,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD954),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (!isDailyRepeat && !selectedDays.contains(true)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('최소 하나의 요일을 선택해주세요.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final now = DateTime.now();
                        int hour = selectedHour;
                        if (selectedAmpm == 1 && selectedHour != 12) {
                          hour += 12;
                        } else if (selectedAmpm == 0 && selectedHour == 12) {
                          hour = 0;
                        }

                        DateTime newProposedTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          hour,
                          selectedMinute,
                        );

                        if (newProposedTime.isBefore(now)) {
                          newProposedTime = newProposedTime.add(const Duration(days: 1));
                        }

                        // 알림 업데이트
                        _updateAlarm(alarm, newProposedTime, isDailyRepeat, selectedDays);
                        Navigator.pop(context);
                        
                        String repeatText = isDailyRepeat 
                            ? "매일" 
                            : "매주 " + selectedDays.asMap().entries
                                .where((e) => e.value)
                                .map((e) => ['월', '화', '수', '목', '금', '토', '일'][e.key])
                                .join(', ');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${alarm['pillName'] ?? '약'} 알림이 ${DateFormat('a h:mm', 'ko_KR').format(newProposedTime)}에 $repeatText로 수정되었습니다.'),
                            backgroundColor: const Color(0xFFFFD954),
                          ),
                        );
                      },
                      child: const Text(
                        '수정하기',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(String isoTime) {
    try {
      final seoul = tz.getLocation('Asia/Seoul');
      final utcTime = DateTime.parse(isoTime);
      final kstTime = tz.TZDateTime.from(utcTime, seoul);
      return DateFormat('a h:mm', 'ko_KR').format(kstTime);
    } catch (e) {
      print('Error formatting time: $e');
      return '시간 오류';
    }
  }

  String _formatRepeatInfo(Map<String, dynamic> alarm) {
    if (alarm['isDailyRepeat'] == true) {
      return '매일 반복';
    } else if (alarm['selectedDays'] != null) {
      final List<bool> selectedDays = List<bool>.from(alarm['selectedDays']);
      final days = ['월', '화', '수', '목', '금', '토', '일'];
      final selectedDayNames = selectedDays.asMap().entries
          .where((e) => e.value)
          .map((e) => days[e.key])
          .join(', ');
      return '매주 $selectedDayNames';
    }
    return '한 번만';
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
          '알림 설정',
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
        child: _alarms.isEmpty
            ? Center(
                child: Text(
                  '설정된 알림이 없습니다.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontFamily: 'NotoSansKR',
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _alarms.length,
                itemBuilder: (context, index) {
                  final alarm = _alarms[index];
                  final formattedTime = _formatTime(alarm['time']);
                  final repeatInfo = _formatRepeatInfo(alarm);
                  
                  return Dismissible(
                    key: Key(alarm['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
                      _deleteAlarm(alarm['id']);
                    },
                    child: ListTile(
                      leading: const Icon(Icons.alarm, color: Color(0xFFFFB300)),
                      title: Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansKR',
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm['pillName'] ?? '알림',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                          Text(
                            repeatInfo,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFFB300),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFFFFB300)),
                            onPressed: () => _showAlarmEditDialog(alarm),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                    '알림 삭제',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'NotoSansKR',
                                    ),
                                  ),
                                  content: Text(
                                    '${alarm['pillName'] ?? '약'} 알림을 삭제하시겠습니까?',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'NotoSansKR',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        '취소',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                          fontFamily: 'NotoSansKR',
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteAlarm(alarm['id']);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${alarm['pillName'] ?? '약'} 알림이 삭제되었습니다.'),
                                            backgroundColor: const Color(0xFFFFD954),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        '삭제',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'NotoSansKR',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
} 