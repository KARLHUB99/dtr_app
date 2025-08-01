import 'dart:convert';
import 'package:dtr_app/model/geofence_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AttendanceService {
  final String baseUrl = 'http://panaderooffice.ddns.net:8080/DTRApi/api';

  String get attendanceUrl => '$baseUrl/get_attendance.php';
  String get getShiftSchedulesUrl => '$baseUrl/get_shifts.php';
  String get serverTimeUrl => '$baseUrl/get_server_time.php';
  String get employeeUrl => '$baseUrl/get_employee.php';
  String get submitAdjustmentUrl => '$baseUrl/submit_time_adjustment.php';
  String get getGeoUrl => '$baseUrl/get_department.php';
  String get getRecentLogs => '$baseUrl/get_recent_attendance.php';
  String get getTodaysLog => '$baseUrl/get_attendance_today.php';
  String get requestOvertimeUrl => '$baseUrl/request_ot.php';
  String get createAttendanceUrl =>
      '$baseUrl/create_attendance_with_approval.php';
  String get createOffsetUrl => '$baseUrl/create_offset.php';
  String get getAttendanceLogsUrl => '$baseUrl/get_attendance_logs.php';

  // Fetch server time from API
  Future<DateTime?> fetchServerDateTime() async {
    try {
      final response = await http.get(Uri.parse(serverTimeUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['server_time'] != null) {
          return DateTime.parse(data['server_time']);
        } else {
          throw Exception('Server time not found in response');
        }
      } else {
        throw Exception('Failed to fetch server time: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching server time: $e');
    }
  }

   Future<List<String>> fetchShiftSchedules() async {
    try {
      final response = await http.get(Uri.parse(getShiftSchedulesUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // data is expected to be a List of strings, e.g. ["06:00 AM - 03:00 PM", ...]
        return data.cast<String>();
      } else {
        throw Exception('Failed to load shift schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shift schedules: $e');
    }
  }

  // Fetch attendance data
  Future<List<dynamic>> fetchAttendanceData() async {
    try {
      final response = await http.get(Uri.parse(attendanceUrl));

      if (response.statusCode == 200) {
        final data = _parseResponse(response.body);
        if (data is List<dynamic>) {
          return data;
        } else {
          throw Exception('Unexpected response format: Expected a list');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attendance data: $e');
    }
  }

  Future<List<dynamic>> fetchRecentLogs(String employeeId) async {
    try {
      final url = Uri.parse('$getRecentLogs?employee_id=$employeeId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = _parseResponse(response.body);
        if (data is List<dynamic>) {
          return data;
        } else {
          throw Exception('Unexpected response format: Expected a list');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attendance data: $e');
    }
  }

  Future<List<dynamic>> fetchAttendanceLogs(
    String departmentId,
    String fromDate, // Changed parameter name to match backend
    String toDate, // Changed parameter name to match backend
  ) async {
    try {
      final url = Uri.parse(
        '$getAttendanceLogsUrl?department_id=$departmentId&from_date=$fromDate&to_date=$toDate',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = _parseResponse(response.body);
        if (data is List<dynamic>) {
          return data;
        } else {
          throw Exception('Unexpected response format: Expected a list');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attendance data: $e');
    }
  }

  Future<GeofenceModel?> fetchGeofenceForDepartment(String departmentId) async {
    final url = Uri.parse(getGeoUrl);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      // Find the geofence info for the matching department
      final matching = data.firstWhere(
        (item) => item['DepartmentID'] == departmentId,
        orElse: () => null,
      );

      if (matching != null) {
        return GeofenceModel.fromJson(matching);
      }
    }

    return null;
  }

 Future<Map<String, dynamic>> handleAction({
  required String label,
  required String idNumber,
  required String apiUrl,
  required String currentTime,
  String? photoBase64,
}) async {
  try {
    final payload = <String, dynamic>{
      'employee_id': idNumber,
    };

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    switch (label.toUpperCase()) {
      case "TIME IN":
        payload['time_in'] = currentTime;
        payload['photo'] = photoBase64;
        break;
      case "LUNCH OUT":
        payload['lunch_out'] = currentTime;
        payload['attendance_date'] = today;
        payload['updated_at'] = DateTime.now().toIso8601String();
        payload['photo'] = photoBase64;
        break;
      case "LUNCH IN":
        payload['lunch_in'] = currentTime;
        payload['attendance_date'] = today;
        payload['updated_at'] = DateTime.now().toIso8601String();
        payload['photo'] = photoBase64;
        break;
      case "TIME OUT":
        payload['time_out'] = currentTime;
        payload['attendance_date'] = today;
        payload['updated_at'] = DateTime.now().toIso8601String();
        payload['photo'] = photoBase64;
        break;
      default:
        throw Exception('Unsupported action: $label');
    }

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to perform action: ${response.statusCode} ${response.body}',
      );
    }
  } catch (e) {
    throw Exception('Error performing action: $e');
  }
}


  // Fetch employee full name
  Future<String?> fetchEmployeeName(String employeeId) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {'employee_id': employeeId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['employee_name'] != null) {
          return data['employee_name'];
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching employee name: $e');
      }
      return null;
    }
  }

  // Fetch attendance status for a specific employee
  // Future<Map<String, dynamic>> getAttendanceStatus(String employeeId) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse(getTodaysLog),
  //       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  //       body: {'employee_id': employeeId},
  //     );

  //     if (response.statusCode == 200) {
  //       final data = _parseResponse(response.body);
  //       if (data is Map<String, dynamic>) {
  //         return data;
  //       } else {
  //         throw Exception('Unexpected response format: Expected a map');
  //       }
  //     } else {
  //       throw Exception(
  //         'Failed to fetch attendance status: ${response.statusCode}',
  //       );
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching attendance status: $e');
  //   }
  // }

  // Future<Map<String, bool>> getTodayAttendanceStatus(String employeeId) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse(attendanceUrl),
  //       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  //       body: {'employee_id': employeeId},
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       if (data is List && data.isNotEmpty) {
  //         final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  //         final todayRecord = data.firstWhere(
  //           (record) => record['attendance_date'] == today,
  //           orElse: () => null,
  //         );

  //         if (todayRecord != null) {
  //           return {
  //             'hasTimeIn': (todayRecord['time_in'] ?? '').toString().isNotEmpty,
  //             'hasLunchOut':
  //                 (todayRecord['lunch_out'] ?? '').toString().isNotEmpty,
  //             'hasLunchIn':
  //                 (todayRecord['lunch_in'] ?? '').toString().isNotEmpty,
  //             'hasTimeOut':
  //                 (todayRecord['time_out'] ?? '').toString().isNotEmpty,
  //           };
  //         }
  //       }

  //       // No record for today
  //       return {
  //         'hasTimeIn': false,
  //         'hasLunchOut': false,
  //         'hasLunchIn': false,
  //         'hasTimeOut': false,
  //       };
  //     } else {
  //       throw Exception(
  //         'Failed to fetch attendance data: ${response.statusCode}',
  //       );
  //     }
  //   } catch (e) {
  //     throw Exception("Error checking today's attendance status: $e");
  //   }
  // }

  Future<void> createAttendance({
    required String employeeId,
    required String departmentId,
    required String date, // Format: yyyy-MM-dd
    required String timeIn, // Format: 06:00 AM
    required String timeOut, // Format: 03:00 PM
    required String remarks,
  }) async {
    try {
      String? convertToDateTimeFormat(String? time, String date) {
        if (time == null || time.isEmpty || date.isEmpty) return null;
        try {
          final parsedTime = DateFormat('hh:mm a').parseStrict(time);
          final dateParts = date.split('-');
          if (dateParts.length != 3) {
            throw FormatException('Invalid date format: $date');
          }

          final combined = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            parsedTime.hour,
            parsedTime.minute,
          );
          return DateFormat('yyyy-MM-dd HH:mm:ss').format(combined);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ DateTime conversion error: $e');
          }
          return null;
        }
      }

      final formattedTimeIn = convertToDateTimeFormat(timeIn, date);
      final formattedTimeOut = convertToDateTimeFormat(timeOut, date);

      if (formattedTimeIn == null || formattedTimeOut == null) {
        throw Exception('Invalid time format for Time In or Time Out.');
      }

      final body = {
        'employee_id': employeeId,
        'department_id': departmentId,
        'attendance_date': date,
        'time_in': formattedTimeIn,
        'time_out': formattedTimeOut,
        'remarks': remarks,
      };

      if (kDebugMode) {
        print('📤 Sending body: ${jsonEncode(body)}');
      }

      final response = await http.post(
        Uri.parse(createAttendanceUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print('📥 Raw server response: ${response.body}');
      }

      if (response.body.contains('<html')) {
        throw Exception(
          'Unexpected HTML response from server. Check backend URL or server error.',
        );
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          if (kDebugMode) {
            print(
              '✅ Attendance successfully submitted: ${responseBody['message']}',
            );
          }
        } else {
          throw Exception(
            '❌ Server error: ${responseBody['message'] ?? 'Unknown failure reason.'}',
          );
        }
      } else {
        throw Exception('❌ Failed with status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception: $e');
      }
      throw Exception('Error creating attendance: $e');
    }
  }

  Future<void> createOffset({
    required String employeeId,
    required String departmentId,
    required String date, // Format: yyyy-MM-dd
    required String remarks,
  }) async {
    try {
      final body = {
        'employee_id': employeeId,
        'department_id': departmentId,
        'attendance_date': date,
        'remarks': remarks,
      };

      if (kDebugMode) {
        print('📤 Sending body: ${jsonEncode(body)}');
      }

      final response = await http.post(
        Uri.parse(createOffsetUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print('📥 Raw server response: ${response.body}');
      }

      if (response.body.contains('<html')) {
        throw Exception(
          'Unexpected HTML response from server. Check backend URL or server error.',
        );
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          if (kDebugMode) {
            print(
              '✅ Offset successfully submitted: ${responseBody['message']}',
            );
          }
        } else {
          throw Exception(
            '❌ Server error: ${responseBody['message'] ?? 'Unknown failure reason.'}',
          );
        }
      } else {
        throw Exception('❌ Failed with status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception: $e');
      }
      throw Exception('Error creating attendance: $e');
    }
  }

 Future<void> submitAttendanceForApproval({
  required int attendanceID,
  required String employeeID,
  String? updateDepartment,
  String? timeInRequested,
  String? timeOutRequested,
  String? remarks,
  required DateTime updatedAt,
  String? shiftSchedule, // NEW: shift schedule parameter
}) async {
  try {
    String? convertToDateTimeFormat(String? time) {
      if (time == null || time.isEmpty) return null;
      final format = DateFormat('hh:mm a');
      try {
        final parsedTime = format.parse(time);
        String datePart = DateFormat('yyyy-MM-dd').format(DateTime.now());
        return "$datePart ${DateFormat('HH:mm:ss').format(parsedTime)}";
      } catch (e) {
        return time;
      }
    }

    final formattedUpdatedAt = DateFormat('yyyy-MM-dd').format(updatedAt);

    final body = {
      'attendance_id': attendanceID.toString(),
      'employee_id': employeeID,
      'updated_at': formattedUpdatedAt,
      'update_department': updateDepartment ?? '',
      'time_in_requested': convertToDateTimeFormat(timeInRequested) ?? '',
      'time_out_requested': convertToDateTimeFormat(timeOutRequested) ?? '',
      'remarks': remarks,
      'shift_schedule': shiftSchedule ?? '', // NEW: add shift schedule here
    };

    if (kDebugMode) {
      print('📤 Sending body: $body');
    }

    final response = await http.post(
      Uri.parse(submitAdjustmentUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);

      if (responseBody['status'] == 'success' &&
          (responseBody['message']?.toString().toLowerCase().contains(
                'successfully',
              ) ??
              false)) {
        if (kDebugMode) {
          print('✅ Attendance submitted successfully for approval!');
        }
      } else {
        String errorMessage = responseBody['error'] ?? 'Unknown error';
        throw Exception(
          'Failed to submit attendance for approval: $errorMessage',
        );
      }
    } else {
      throw Exception(
        'Failed to submit attendance for approval: ${response.statusCode}',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Error submitting attendance: $e');
    }
    throw Exception('Error submitting attendance: $e');
  }
}


  Future<void> requestOvertime({
    required String employeeId,
    required String departmentId,
    required String date, // Format: yyyy-MM-dd
    required String timeIn, // Format: 06:00 AM
    required String timeOut, // Format: 03:00 PM
    required String otRequestText, // Value from OTRequestTextController
  }) async {
    try {
      String? convertToDateTimeFormat(String? time, String date) {
        if (time == null || time.isEmpty || date.isEmpty) return null;
        try {
          final parsedTime = DateFormat('hh:mm a').parseStrict(time);
          final dateParts = date.split('-');
          if (dateParts.length != 3) {
            throw FormatException('Invalid date format: $date');
          }

          final combined = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            parsedTime.hour,
            parsedTime.minute,
          );
          return DateFormat('yyyy-MM-dd HH:mm:ss').format(combined);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ DateTime conversion error: $e');
          }
          return null;
        }
      }

      final formattedTimeIn = convertToDateTimeFormat(timeIn, date);
      final formattedTimeOut = convertToDateTimeFormat(timeOut, date);

      if (formattedTimeIn == null || formattedTimeOut == null) {
        throw Exception('Invalid time format for Time In or Time Out.');
      }

      if (otRequestText.isEmpty) {
        throw Exception('❌ Overtime Request field cannot be empty.');
      }

      final body = {
        'employee_id': employeeId,
        'department_id': departmentId,
        'attendance_date': date,
        'time_in': formattedTimeIn,
        'time_out': formattedTimeOut,
        'ot_request': otRequestText.trim(), // Value from the controller
      };

      if (kDebugMode) {
        print('📤 Sending body: ${jsonEncode(body)}');
      }

      final response = await http.post(
        Uri.parse(requestOvertimeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print('📥 Raw server response: ${response.body}');
      }

      if (response.body.contains('<html')) {
        throw Exception(
          'Unexpected HTML response from server. Check backend URL or server error.',
        );
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          if (kDebugMode) {
            print(
              '✅ Overtime request successfully submitted: ${responseBody['message']}',
            );
          }
        } else {
          throw Exception(
            '❌ Server error: ${responseBody['message'] ?? 'Unknown failure reason.'}',
          );
        }
      } else {
        throw Exception('❌ Failed with status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception: $e');
      }
      throw Exception('Error creating overtime request: $e');
    }
  }

  // Helper method to parse and validate JSON responses
  dynamic _parseResponse(String responseBody) {
    try {
      return jsonDecode(responseBody);
    } catch (e) {
      throw Exception('Invalid JSON response: $e');
    }
  }
}
