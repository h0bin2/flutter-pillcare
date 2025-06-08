import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/intro_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'app_settings_provider.dart';
import 'package:flutter/widgets.dart';
import 'screens/medicine_info_screen.dart';
import 'screens/home_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// 알림 응답 핸들러 (알림 탭 시)
void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (payload != null && payload.isNotEmpty) {
    debugPrint('notification payload: $payload');
    try {
      final Map<String, dynamic> pillData = jsonDecode(payload);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(
          navigatorKey.currentContext!,
          '/medicine_info',
          arguments: pillData,
        );
      });
    } catch (e) {
      debugPrint('Failed to parse notification payload: $e');
    }
  }
}

// 글로벌 네비게이터 키
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  // 알림 플러그인 초기화
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    requestCriticalPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  // iOS 알림 권한 요청
  if (Platform.isIOS) {
    final bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
    debugPrint('iOS 알림 권한 요청 결과: $result');
  }

  // Android 알림 채널 설정
  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pillcare_notification_channel',
      'PillCare 알림',
      description: '약 복용 시간을 알려줍니다.',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('.env 파일 로드 실패: $e');
  }

  String? nativeAppKey = 'f05090355f9d1379adbc5395f7165d18';
  if (nativeAppKey != null) {
    try {
      KakaoSdk.init(nativeAppKey: nativeAppKey);
      print('Kakao SDK 초기화 성공');
    } catch (e) {
      print('Kakao SDK 초기화 실패: $e');
    }
  } else {
    print('NATIVE_APP_KEY가 .env 파일에 설정되지 않았습니다.');
  }

  await NaverMapSdk.instance.initialize(
      clientId: 'c22uzm0ayz',
      onAuthFailed: (ex) {
        print("********* 네이버맵 인증오류 : $ex *********");
      });

  final appSettings = AppSettingsProvider();
  await appSettings.loadSettings();

  runApp(
    ChangeNotifierProvider.value(
      value: appSettings,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, appSettings, child) {
        return MaterialApp(
          title: 'PILLCARE',
          theme: ThemeData(
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: appSettings.isDarkMode ? Colors.black : Colors.white,
            brightness: appSettings.isDarkMode ? Brightness.dark : Brightness.light,
            fontFamily: 'NotoSansKR',
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
          ],
          navigatorObservers: [routeObserver],
          navigatorKey: navigatorKey,
          home: const IntroScreen(),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/medicine_info': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return MedicineInfoScreen(pillData: args);
            },
          },
        );
      },
    );
  }
}
