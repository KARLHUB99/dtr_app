import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String apiUrl =
      'http://panaderooffice.ddns.net:8080/DTRApi/api/get_user.php';
  final String departmentsApiUrl =
      'http://panaderooffice.ddns.net:8080/DTRApi/api/get_user_departments.php';
  final String getdepartmentsApiUrl =
      'http://panaderooffice.ddns.net:8080/DTRApi/api/get_department.php';

  Future<List<Map<String, String>>> fetchUsers({String? department}) async {
    final uri = Uri.parse(
      department != null && department.isNotEmpty
          ? '$apiUrl?department=$department'
          : apiUrl,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, String>>((user) {
        return {
          'UserName': user['UserName'].toString(),
          'FullName': user['FullName'].toString(),
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }
  }

  Future<List<String>> fetchDepartments() async {
    try {
      final response = await http.get(Uri.parse(getdepartmentsApiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((dept) => dept['DepartmentName'].toString()).toList();
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserDepartments(String username) async {
    try {
      final response = await http.post(
        Uri.parse(departmentsApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Validate and process the response
        return data
            .where((item) => item['UserName'] == username) // Filter by username
            .map(
              (item) => {
                'UserName': item['UserName'],
                'DepartmentID': item['DepartmentID'],
                'Department': item['Department'],
              },
            )
            .toList();
      } else {
        throw Exception('Failed to fetch departments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}
