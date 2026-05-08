import 'dart:convert';
import 'package:http/http.dart' as http;

class ShareService {
  static const String _baseUrl =
      "https://taco-share-561562660997.australia-southeast1.run.app";

  static Future<String> shareTodo({
    required String content,
    required String remark,
    required int? ddl,
  }) async {
    final uri = Uri.parse("$_baseUrl/api/share");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "content": content,
        "remark": remark,
        "ddl": ddl,
      })
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception("server error ${response.statusCode}");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return data["pin"] as String;
  }

  static Future<Map<String, dynamic>> getSharedTodo(String pin) async {
    final resp = await http
        .get(Uri.parse("$_baseUrl/api/share/$pin"))
        .timeout(const Duration(seconds: 5));

    if (resp.statusCode != 200) {
      throw Exception("server error ${resp.statusCode}");
    }

    final Map<String, dynamic> data = jsonDecode(resp.body);

    if (data["done"] != true) {
      throw Exception("invalid response");
    }

    return data;
  }
}
