import 'package:data_table_2/data_table_2.dart';
import 'package:dtr_app/pages/auth_popup_page.dart';
import 'package:dtr_app/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AttendanceApprovalPage extends StatefulWidget {
  const AttendanceApprovalPage({super.key});

  @override
  State<AttendanceApprovalPage> createState() => _AttendanceApprovalPageState();
}

class _AttendanceApprovalPageState extends State<AttendanceApprovalPage> {
  final TextEditingController costCenterController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  String searchQuery = '';

  String? selectedDepartment;
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  bool isAuthenticated = false;
  bool isLoading = true;
  List<Map<String, String>> departments = [];
  List<String> departmentIds = [];
  String? authenticatedUsername;
  List<dynamic> attendanceApprovalData = [];
  List<Map<String, dynamic>> fetchedDepartments =
      []; // Store fetched departments
  List<dynamic> filteredApprovalData = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAuthPopup();
      }
    });
  }

  void _showAuthPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AuthPopupPage(
            onAuthenticated: (String username, String fullName) async {
              setState(() {
                isAuthenticated = true;
                authenticatedUsername = username;
                fullNameController.text = fullName;
              });
              await _fetchDepartments(username);
              await fetchAttendanceApproval();
            },
          ),
    );
  }

  Future<void> _fetchDepartments(String username) async {
    final userService = UserService();
    try {
      final departments = await userService.getUserDepartments(username);
      if (!mounted) return;
      setState(() {
        fetchedDepartments = departments;
        departmentIds =
            departments
                .map((dept) => dept['DepartmentID'].toString())
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

  Future<void> fetchAttendanceApprovalData({
    required String departmentId,
    required String fromDate,
    required String toDate,
  }) async {
    setState(() {
      isLoading = true;
    });

    final uri = Uri.parse(
      'http://panaderooffice.ddns.net:8080/DTRApi/api/get_attendance_approval.php'
      '?department_id=$departmentId&from_date=$fromDate&to_date=$toDate',
    );

    final response = await http.get(uri);

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      try {
        attendanceApprovalData = json.decode(response.body);
        filteredApprovalData = List.from(
          attendanceApprovalData,
        ); // initially same
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error parsing attendance data')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load attendance data')),
      );
    }
  }

  //void _filterSearchResults(String query) {
  //setState(() {
  //searchQuery = query;
  ////  if (query.isEmpty) {
  //  filteredApprovalData = List.from(attendanceApprovalData);
  //} else {
  // filteredApprovalData =
  //  attendanceApprovalData.where((item) {
  //  final name = (item['GivenName'] ?? '').toLowerCase();
  // return name.contains(query.toLowerCase());
  //  }).toList();
  // }
  // });
  //}

  Future<void> fetchAttendanceApproval() async {
    final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
    final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);

    if (selectedDepartment != null) {
      await fetchAttendanceApprovalData(
        departmentId: selectedDepartment!,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), // Icon color
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
        ), // Action icon color
        backgroundColor: const Color(0xFFDA1A29), // Panadero-inspired red
        title: Text(
          'A P P R O V A L',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 17,
            textStyle: TextStyle(
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),

        elevation: 5,
        centerTitle: false,
      ),
      body:
          isAuthenticated
              ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 20, // Horizontal spacing between items
                          runSpacing: 16, // Vertical spacing between rows
                          alignment: WrapAlignment.center,
                          children: [
                            // Cost Center Input
                            Row(
                              children: [
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.red.shade400,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.red.shade700,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      value: selectedDepartment,
                                      items:
                                          fetchedDepartments.map((dept) {
                                            final departmentId =
                                                dept['DepartmentID'].toString();
                                            return DropdownMenuItem<String>(
                                              value: departmentId,
                                              child: Text(
                                                "$departmentId - ${dept['Department']}",
                                                style: GoogleFonts.rajdhani(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (value) async {
                                        setState(() {
                                          selectedDepartment = value;
                                          isLoading = true;
                                        });
                                        await fetchAttendanceApproval();
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
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                                          await fetchAttendanceApproval();
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                                            toDate = picked;
                                            isLoading = true;
                                          });
                                          await fetchAttendanceApproval();
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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

                            // From Date Button

                            // To Date Button
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
                  Expanded(
                    child:
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : attendanceApprovalData.isEmpty
                            ? Center(
                              child: Text(
                                'No attendance approvals found.',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                            : PaginatedDataTable2(
                              headingRowHeight: 22,
                              dataRowHeight: 25,
                              columnSpacing: 10,
                              horizontalMargin: 8,
                              minWidth: 600,
                              headingRowColor: WidgetStateProperty.all(
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
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'NAME',
                                    style: GoogleFonts.rajdhani(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Center(
                                    child: Text(
                                      'ATTENDANCE DATE',
                                      style: GoogleFonts.rajdhani(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Center(
                                    child: Text(
                                      'TIME IN',
                                      style: GoogleFonts.rajdhani(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Center(
                                    child: Text(
                                      'TIME OUT',
                                      style: GoogleFonts.rajdhani(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'REASON',
                                    style: GoogleFonts.rajdhani(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Center(
                                    child: Text(
                                      'REQUEST TYPE',
                                      style: GoogleFonts.rajdhani(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Center(
                                    child: Text(
                                      'OT REQUEST',
                                      style: GoogleFonts.rajdhani(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                DataColumn(
                                  label: Text(
                                    'STATUS',
                                    style: GoogleFonts.rajdhani(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'ACTION',
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              source: ApprovalDataSource(
                                attendanceApprovalData,
                                (action, id) {
                                  _showConfirmationDialog(action, id);
                                },
                              ),

                              rowsPerPage: attendanceApprovalData.length,
                              showCheckboxColumn: false,
                            ),
                  ),
                ],
              )
              : const Center(child: Text('Authenticating...')),
    );
  }

  void _showConfirmationDialog(String action, String approvalId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '$action Adjustment',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.red[800], // Panadero red
            ),
          ),
          content: Text(
            'Are you sure you want to $action this adjustment?',
            style: GoogleFonts.rajdhani(fontSize: 16, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[800],
                textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                handleApproval(action, approvalId);
              },
              child: Text(
                action,
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSubmitting = false; // Track if a request is in progress

  Future<void> handleApproval(String decision, String approvalId) async {
    if (authenticatedUsername == null || authenticatedUsername!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not authenticated')),
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final url = Uri.parse(
      'http://panaderooffice.ddns.net:8080/DTRApi/api/save_approval.php',
    );

    final requestData = {
      'ApprovalID': approvalId.trim(),
      'Reviewer': fullNameController.text,
      'Decision': decision,
    };

    try {

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      debugPrint('POST $url');
      debugPrint('Request: ${jsonEncode(requestData)}');
      debugPrint('Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${decision.toUpperCase()} success')),
          );

          // Small delay to let server complete DB updates before fetching new data
          await Future.delayed(const Duration(milliseconds: 500));

          await fetchAttendanceApproval(); // Refresh table or UI data

          // Optional: reset any selected approval states here if applicable
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Approval failed')),
          );
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server error: ${errorResponse['error'] ?? response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

class ApprovalDataSource extends DataTableSource {
  final List<dynamic> data;
  final Function(String, String) onAction;

  ApprovalDataSource(this.data, this.onAction);

  @override
  DataRow getRow(int index) {
    final approval = data[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text('${approval['Surname']}, ${approval['GivenName']}')),
        DataCell(Center(child: Text(approval['AttendanceDate'] ?? ''))),
        DataCell(Center(child: Text(approval['TimeIn'] ?? ''))),
        DataCell(Center(child: Text(approval['TimeOut'] ?? ''))),
        DataCell(Text(approval['Remarks'] ?? '')),
        DataCell(Center(child: Text(approval['RequestType'] ?? ''))),
        DataCell(Center(child: Text(approval['OTReq'] ?? ''))),

        DataCell(
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: _getStatusColor(approval['ApprovalStatus']),
              ),
              const SizedBox(width: 4),
              Text(
                approval['ApprovalStatus'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        DataCell(
          SizedBox(
            width: 200, // You can reduce this if needed
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 4, 92, 19),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 12,
                      ),
                    ),
                    onPressed:
                        () => onAction(
                          'Approved',
                          approval['ApprovalID'].toString(),
                        ),
                    child: Text(
                      'APPROVE',
                      style: GoogleFonts.rajdhani(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 187, 7, 7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 12,
                      ),
                    ),
                    onPressed:
                        () => onAction(
                          'Rejected',
                          approval['ApprovalID'].toString(),
                        ),
                    child: Text(
                      'REJECT',
                      style: GoogleFonts.rajdhani(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
}

Color _getStatusColor(String? status) {
  switch (status?.toLowerCase()) {
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'pending':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}
