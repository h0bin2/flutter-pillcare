import 'dart:io';
import 'package:dio/dio.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart'; // AuthService의 static 멤버(baseUrl, dio 인스턴스) 접근을 위함
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecordService {
  static final Dio _dio = AuthService.getDioInstance();

  static Future<Map<String, dynamic>?> uploadImage(XFile imageFile) async {
    String fileName = imageFile.path.split('/').last;
    FormData formData = FormData.fromMap({
      "original_image": await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    if (kDebugMode) {
      print('[RecordService] Uploading image: ${imageFile.path}');
      print('[RecordService] Base URL for upload (Dio): ${_dio.options.baseUrl}');
      print('[RecordService] Target endpoint for upload: /api/record/insert');
    }

    try {
      final response = await _dio.post(
        '/api/record/insert',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (kDebugMode) {
          print('[RecordService] Image upload successful: ${response.data}');
        }
        return response.data as Map<String, dynamic>;
      } else {
        if (kDebugMode) {
          print('[RecordService] Image upload failed: ${response.statusCode}, ${response.data}');
        }
        return {'error': 'Upload failed', 'statusCode': response.statusCode, 'detail': response.data};
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[RecordService] Image upload DioException: ${e.message}');
        if (e.response != null) {
          print('[RecordService] DioException response: ${e.response?.data}');
        }
      }
      return {'error': 'DioException', 'message': e.message, 'detail': e.response?.data};
    } catch (e) {
      if (kDebugMode) {
        print('[RecordService] Image upload Exception: $e');
      }
      return {'error': 'Exception', 'message': e.toString()};
    }
  }

  static Future<bool> deleteRecord(int recordId) async {
    final String endpoint = '/api/record/delete';

    if (kDebugMode) print('Attempting to delete record ID: $recordId using Dio at $endpoint?record_id=$recordId');

    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: {'record_id': recordId},
      );

      if (kDebugMode) {
        print('Delete response status (Dio): ${response.statusCode}');
        print('Delete response data (Dio): ${response.data}');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        print('[RecordService] Delete request returned status ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error deleting record (DioException): ${e.message}');
        if (e.response != null) {
          print('DioException response for delete: ${e.response?.data}');
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error deleting record (General Exception): $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>?> getRecords() async {
    // 실제 서버에서 복용 기록을 받아오는 로직으로 복구
    try {
      final response = await _dio.get('/api/record/read');
      if (kDebugMode) print('[RecordService] Raw API response data: ' + response.data.toString());
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          return (response.data as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else if (response.data is Map && response.data['records'] is List) {
          // 혹시 records 키로 감싸져 있을 경우
          return (response.data['records'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          if (kDebugMode) print('[RecordService] getRecords: 응답 데이터가 List 형태가 아님: \\${response.data}');
          return null;
        }
      } else {
        if (kDebugMode) print('[RecordService] getRecords: 서버 오류 - \\${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      if (kDebugMode) print('[RecordService] getRecords: DioException - \\${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) print('[RecordService] getRecords: 예상치 못한 오류 - \\${e}');
      return null;
    }
  }

  static Future<bool> deletePill({required int recordId, required int pillId}) async {
    final String endpoint = '/api/record/pill_delete';
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: {'record_id': recordId, 'pill_id': pillId},
      );
      if (kDebugMode) {
        print('Delete pill response status: \\${response.statusCode}');
        print('Delete pill response data: \\${response.data}');
      }
      if (response.statusCode == 200) {
        return true;
      } else {
        print('[RecordService] Delete pill request returned status \\${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error deleting pill (DioException): \\${e.message}');
        if (e.response != null) {
          print('DioException response for delete pill: \\${e.response?.data}');
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error deleting pill (General Exception): \\${e}');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>?> getRecommendations({bool forceNetwork = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = 'recommendations_date';
    final dataKey = 'recommendations_data';
    final cachedDate = prefs.getString(todayKey);
    final cachedData = prefs.getString(dataKey);
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (!forceNetwork && cachedDate == todayStr && cachedData != null) {
      print('[RecordService] getRecommendations: 캐시 사용 (date: \\${cachedDate ?? 'null'})');
      print('[RecordService] getRecommendations: 캐시 데이터 내용: $cachedData');
      try {
        final decoded = jsonDecode(cachedData);
        if (decoded is List) {
          return decoded.map((e) => e as Map<String, dynamic>).toList();
        }
      } catch (e) {
        if (kDebugMode) print('[RecordService] getRecommendations: 캐시 파싱 오류 - $e');
      }
    }
    print('[RecordService] getRecommendations: 네트워크 호출');
    try {
      final response = await _dio.get('/api/recommend/medicine');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map && response.data['recommendations'] is List) {
          final recs = (response.data['recommendations'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          // 캐시에 저장
          prefs.setString(todayKey, todayStr);
          prefs.setString(dataKey, jsonEncode(recs));
          return recs;
        } else {
          if (kDebugMode) print('[RecordService] getRecommendations: 응답 데이터에 recommendations 리스트가 없음: \\${response.data}');
          return null;
        }
      } else {
        if (kDebugMode) print('[RecordService] getRecommendations: 서버 오류 - \\${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      if (kDebugMode) print('[RecordService] getRecommendations: DioException - \\${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) print('[RecordService] getRecommendations: 예상치 못한 오류 - \\${e}');
      return null;
    }
  }

  /// 개발용: 추천 캐시 강제 초기화 함수
  static Future<void> clearRecommendationsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recommendations_date');
    await prefs.remove('recommendations_data');
    if (kDebugMode) print('[RecordService] 추천 캐시 초기화 완료');
  }
} 