import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String loginApiUrl =
      'https://panaderooffice.ddns.net:8080/DTRApi/api/login_user.php';
  final String departmentsApiUrl =
      'https://panaderooffice.ddns.net:8080/DTRApi/api/get_user_departments.php';

  // Verify user credentials
  Future<Map<String, dynamic>> verifyCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(loginApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to authenticate: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // Fetch user departments based on username
  Future<List<Map<String, dynamic>>> getUserDepartments(String username) async {
    try {
      final response = await http.post(
        Uri.parse(departmentsApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch departments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}