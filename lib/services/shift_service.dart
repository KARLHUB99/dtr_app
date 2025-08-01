import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ShiftService {
  final String employeeApiUrl =
      'http://panaderooffice.ddns.net:8080/DTRApi/api/get_employee.php';
  final String shiftApiUrl =
      'http://panaderooffice.ddns.net:8080/DTRApi/api/get_shift.php';
  final String saveShiftApiUrl =
      'http://panaderooffice.ddns.net:8080/DTRApi/api/save_shift.php';

  // Fetch employee data
  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse(employeeApiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map<Map<String, dynamic>>((employee) {
          return {
            'name': '${employee['GivenName']} ${employee['Surname']}',
            'id': employee['EmployeeID'].toString(),
            'departmentId': employee['DepartmentID'].toString(),
            'workId': employee['WorkInfoID'].toString(),
            'workstatus': employee['WorkStatus'].toString(),
          };
        }).toList();
      } else {
        throw Exception('Failed to load employees: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching employee data: $e');
    }
  }

  // Fetch assigned shifts
  Future<List<Map<String, dynamic>>> fetchAssignedShifts() async {
    try {
      final response = await http.get(Uri.parse(shiftApiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map<Map<String, dynamic>>((item) {
          final fullName =
              '${item['GivenName'] ?? ''} ${item['Surname'] ?? ''}';
          final shiftType = item['ShiftType'] ?? '---';

          final startRaw = item['ShiftStart']?.toString();
          final endRaw = item['ShiftEnd']?.toString();

          // Format the start and end dates
          final start =
              startRaw != null
                  ? DateFormat(
                    'hh:mm a',
                  ).format(DateTime.parse(startRaw).toLocal())
                  : '--';
          final end =
              endRaw != null
                  ? DateFormat(
                    'hh:mm a',
                  ).format(DateTime.parse(endRaw).toLocal())
                  : '--';

          return {
            'employee': fullName.trim(),
            'shift': shiftType,
            'start': start,
            'end': end,
          };
        }).toList();
      } else {
        throw Exception('Failed to load shifts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching assigned shifts: $e');
    }
  }

  // Save shift
  Future<Map<String, dynamic>> saveShift({
    required String employeeId,
    required String departmentId,
    required String shiftStart,
    required String shiftEnd,
    required String shiftType,
  }) async {
    try {
      final payload = {
        'EmployeeID': employeeId,
        'DepartmentID': departmentId,
        'ShiftStart': shiftStart,
        'ShiftEnd': shiftEnd,
        'ShiftType': shiftType,
      };

      final response = await http.post(
        Uri.parse(saveShiftApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode != 200 || result.containsKey('error')) {
        return {'error': result['error'] ?? 'Failed to save shift'};
      }

      return result; // expected to contain 'status' on success
    } catch (e) {
      return {'error': 'Exception: $e'};
    }
  }
}
