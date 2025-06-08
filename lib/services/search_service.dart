import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class SearchService {
  static Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/search?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('검색 중 오류가 발생했습니다.');
      }
    } catch (e) {
      print('검색 서비스 오류: $e');
      throw Exception('검색 서비스에 연결할 수 없습니다.');
    }
  }

  static Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/search/autocomplete?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('자동완성 중 오류가 발생했습니다.');
      }
    } catch (e) {
      print('자동완성 서비스 오류: $e');
      throw Exception('자동완성 서비스에 연결할 수 없습니다.');
    }
  }
} 