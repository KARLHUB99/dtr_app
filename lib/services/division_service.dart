import 'dart:convert';
import 'package:http/http.dart' as http;

class DivisionService {
  final String updateWorkInfoUrl =
      'http://panaderooffice.ddns.net:8080/DTRApi/api/update_work_info.php';

  Future<Map<String, dynamic>> saveChanges({
    required String employeeId,
    required String workInfoId,
    required String departmentId,
    required String workStatus,
  }) async {
    try {
      final payload = {
        'EmployeeID': employeeId,
        'WorkInfoID': workInfoId,
        'DepartmentID': departmentId,
        'WorkStatus': workStatus,
      };

      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(updateWorkInfoUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Check the status code and parse the response
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);

        // Check if the 'success' key is true
        if (result['success'] == true) {
          // If the update was successful, return the success message or any other data
          return {
            'success': true,
            'message': result['message'] ?? 'Update successful.',
          };
        } else {
          // If there was an error, throw an exception with the error message
          final errorMessage = result['error'] ?? 'Unknown error occurred';
          throw Exception('Failed to update: $errorMessage');
        }
      } else {
        // If the response status is not 200, handle the failure case
        throw Exception('Failed to update: ${response.body}');
      }
    } catch (e) {
      // More specific error handling
      if (e is http.ClientException) {
        throw Exception('Network error: Unable to reach the server. Please check your connection.');
      } else if (e is FormatException) {
        throw Exception('Invalid server response format.');
      } else {
        throw Exception('Error saving work info: $e');
      }
    }
  }
}
