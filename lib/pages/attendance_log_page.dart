// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:dtr_app/pages/auth_popup_page.dart';
import 'package:dtr_app/services/attendance_service.dart';
import 'package:dtr_app/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AttendanceLogPage extends StatefulWidget {
  const AttendanceLogPage({super.key});

  @override
  _AttendanceLogPageState createState() => _AttendanceLogPageState();
}

class _AttendanceLogPageState extends State<AttendanceLogPage> {
  DateTime fromDate = DateTime.now(); // Initialize with current date
  DateTime toDate = DateTime.now(); // Initialize with current date

  List<dynamic> attendanceData = [];
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();
  TextEditingController departmentnameController = TextEditingController();

  String? selectedDepartment;

  List<Map<String, dynamic>> fetchedDepartments =
      []; // Store fetched departments

  List<String> departmentIds = [];

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAuthPopup();
      }
    });
  }

  Future<void> fetchAttendanceLogs() async {
    final attendanceService = AttendanceService();
    if (selectedDepartment == null) return;

    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await attendanceService.fetchAttendanceLogs(
        selectedDepartment!,
        DateFormat('yyyy-MM-dd').format(fromDate),
        DateFormat('yyyy-MM-dd').format(toDate),
      );

      if (!mounted) return;
      setState(() {
        attendanceData = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAuthPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AuthPopupPage(
            onAuthenticated: (String username, String fullName) async {
              await _fetchDepartments(username);
              fetchAttendanceLogs(); // Fetch attendance data after auth
            },
          ),
    );
  }

  // Fetch departments based on the authenticated username
  Future<void> _fetchDepartments(String username) async {
    try {
      final departments = await _userService.getUserDepartments(username);
      if (!mounted) return;
      setState(() {
        fetchedDepartments = departments;
        departmentIds =
            departments
                .map((dept) => dept['DepartmentID'] as String)
                .toSet()
                .toList();

        selectedDepartment =
            departmentIds.isNotEmpty ? departmentIds.first : null;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching departments: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text('Failed to fetch departments: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Warm background color
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), // Icon color
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
        ), // Action icon color
        backgroundColor: const Color(0xFFDA1A29), // Panadero-inspired red
        title: Text(
          'L O G S',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 17,
            textStyle: const TextStyle(
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        centerTitle: false,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB84D2D)),
              )
              : errorMessage.isNotEmpty
              ? Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                ),
              )
              : Column(
                children: [
                  const SizedBox(height: 4),
                  // Filters Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    child: Wrap(
                      spacing: 20, // Horizontal spacing between items
                      runSpacing: 16, // Vertical spacing between rows
                      alignment: WrapAlignment.center,
                      children: [
                        // Department Dropdown
                        Row(
                          children: [
                            // From Date Picker
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'COST CENTER',
                                    labelStyle: GoogleFonts.rajdhani(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.apartment,
                                      color: Colors.red,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      241,
                                      240,
                                      240,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red.shade400,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red.shade700,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  value: selectedDepartment,
                                  items:
                                      fetchedDepartments.map((dept) {
                                        return DropdownMenuItem<String>(
                                          value: dept['DepartmentID'],
                                          child: Text(
                                            "${dept['DepartmentID']} - ${dept['Department']}",
                                            style: GoogleFonts.rajdhani(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) async {
                                    setState(() {
                                      selectedDepartment = value;
                                      isLoading = true;
                                    });
                                    await fetchAttendanceLogs();
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 2),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      241,
                                      240,
                                      240,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: fromDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        fromDate = picked;
                                        isLoading = true;
                                      });
                                      await fetchAttendanceLogs();
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'FROM DATE: ${DateFormat('yyyy-MM-dd').format(fromDate)}',
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 13,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 2),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      241,
                                      240,
                                      240,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: toDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        toDate = picked;
                                        isLoading = true;
                                      });
                                      await fetchAttendanceLogs();
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'TO DATE: ${DateFormat('yyyy-MM-dd').format(toDate)}',
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 13,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(
                    color: Colors.black26,
                    thickness: 1,
                    height: 0.5,
                  ),

                  // Data Table
                  Expanded(
                    child: PaginatedDataTable2(
                      headingRowHeight: 22,
                      dataRowHeight: 35,
                      columnSpacing: 10,
                      horizontalMargin: 8,
                      minWidth: 600,
                      headingRowColor: MaterialStateProperty.all(
                        const Color(0xFFDA1A29),
                      ),
                      headingTextStyle: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      dataTextStyle: GoogleFonts.rajdhani(
                        fontSize: 11,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      columns: const [
                        DataColumn2(label: Text('DATE')),
                        DataColumn2(label: Text('EMPLOYEE NAME')),
                        DataColumn2(label: Center(child: Text('TIME IN'))),
                        DataColumn2(label: Center(child: Text('LUNCH OUT'))),
                        DataColumn2(label: Center(child: Text('LUNCH IN'))),
                        DataColumn2(label: Center(child: Text('TIME OUT'))),
                        DataColumn2(label: Center(child: Text('STATUS'))),
                      ],
                      source: _AttendanceDataSource(
                        attendanceData,
                        searchController.text,
                        context,
                      ),
                      rowsPerPage:
                          attendanceData.isEmpty ? 1 : attendanceData.length,
                      showCheckboxColumn: false,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _LegendItem(color: Colors.yellow, label: 'LATE'),
                        SizedBox(width: 16),
                        _LegendItem(
                          color: Colors.lightGreenAccent,
                          label: 'ON TIME',
                        ),
                        SizedBox(width: 16),
                        _LegendItem(
                          color: Colors.red,
                          label: 'PENDING APPROVAL',
                        ),
                        SizedBox(width: 16),
                        _LegendItem(
                          color: Colors.green,
                          label: 'PRESENT  |  REST DAY  |  APPROVED',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 15.0,
          height: 15.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _AttendanceDataSource extends DataTableSource {
  final List<dynamic> attendanceData;
  final String searchQuery;
  final BuildContext context;

  _AttendanceDataSource(this.attendanceData, this.searchQuery, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= attendanceData.length) return null;
    final attendance = attendanceData[index];
    final fullName = attendance['FullName']?.toLowerCase() ?? '';

    if (searchQuery.isNotEmpty &&
        !fullName.contains(searchQuery.toLowerCase())) {
      return null; // Skip rows that don’t match the search
    }

    return DataRow.byIndex(
      index: index,
      onSelectChanged: (_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceDetailPage(attendance: attendance),
          ),
        );
      },
      cells: [
        DataCell(Text(attendance['AttendanceDate'] ?? '')),
        DataCell(Text(attendance['FullName'] ?? '')),
        DataCell(Center(child: Text(attendance['TimeIn'] ?? ''))),
        DataCell(Center(child: Text(attendance['LunchOut'] ?? ''))),
        DataCell(Center(child: Text(attendance['LunchIn'] ?? ''))),
        DataCell(Center(child: Text(attendance['TimeOut'] ?? ''))),
        DataCell(
          Center(
            child: _StatusDot(color: _getStatusColor(attendance['Status'])),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'FAP':
        return Colors.red;
      case 'L':
        return const Color.fromARGB(255, 243, 229, 30);
      case 'C':
      case 'REST DAY':
        return Colors.green;
      case 'NL':
        return Colors.lightGreenAccent;
      case 'P':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => attendanceData.length;

  @override
  int get selectedRowCount => 0;
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15.0,
      height: 15.0,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
      ),
    );
  }
}

class AttendanceDetailPage extends StatelessWidget {
  final Map<String, dynamic> attendance;

  const AttendanceDetailPage({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          attendance['FullName'] ?? 'Attendance Details',
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFFDA1A29),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildStatusDateRow(
              attendance['Status'],
              attendance['AttendanceDate'],
            ),
            const Divider(),
            _buildPhotoRow(
              'TIME IN',
              attendance['TimeIn'],
              attendance['PhotoTimeIn'],
            ),
            const Divider(),
            _buildPhotoRow(
              'LUNCH OUT',
              attendance['LunchOut'],
              attendance['PhotoLunchOut'],
            ),
            const Divider(),
            _buildPhotoRow(
              'LUCH IN',
              attendance['LunchIn'],
              attendance['PhotoLunchIn'],
            ),
            const Divider(),
            _buildPhotoRow(
              'TIME OUT',
              attendance['TimeOut'],
              attendance['PhotoTimeOut'],
            ),
            const Divider(),
            _buildDetailRow(
              'Late Minutes',
              attendance['LateMinutes']?.toString(),
            ),
            _buildDetailRow('Overtime', attendance['OverTime']?.toString()),
            _buildDetailRow(
              'Night Differential',
              attendance['NightDiffHours']?.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDateRow(String? status, String? date) {
    String statusMessage = '';
    Color statusColor = Colors.grey;

    if (status == 'L') {
      statusMessage = "You're Late";
      statusColor = Colors.yellow.shade700;
    } else if (status == 'NL') {
      statusMessage = "You're On Time";
      statusColor = Colors.green.shade600;
    }
    else if (status == 'FAP') {
      statusMessage = "Pending Approval";
      statusColor = Colors.red;
    } else if (status == 'REST DAY') {
      statusMessage = "Rest Day";
      statusColor = Colors.green;
    } else if (status == 'C') {
      statusMessage = "Attendance Completed";
      statusColor = Colors.green;
    } else {
      statusMessage = "Status: $status";
      statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (statusMessage.isNotEmpty)
            Text(
              statusMessage,
              style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: statusColor,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Date: ${date ?? ''}',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.normal,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(value ?? '', style: GoogleFonts.rajdhani(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoRow(String label, String? time, String? photoBase64) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              (photoBase64 != null)
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(photoBase64),
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                    ),
                  )
                  : const Icon(Icons.person, size: 40, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            '$label: ${time ?? ''}',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
