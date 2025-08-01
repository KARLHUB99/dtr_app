import 'package:data_table_2/data_table_2.dart';
import 'package:dtr_app/pages/auth_popup_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dtr_app/services/attendance_service.dart';
import 'package:dtr_app/services/user_service.dart';
import 'package:intl/intl.dart';

class TimeAdjustmentPage extends StatefulWidget {
  const TimeAdjustmentPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TimeAdjustmentPageState createState() => _TimeAdjustmentPageState();
}

class _TimeAdjustmentPageState extends State<TimeAdjustmentPage> {
  List<dynamic> attendanceData = [];
  List<String> departmentIds = [];
  List<Map<String, String>> departments = []; // List of departments as maps
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();
  TextEditingController departmentNameController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  final TextEditingController offsetDateFromController =
      TextEditingController();
  final TextEditingController offsetDateToController = TextEditingController();
  final AttendanceService attendanceService = AttendanceService();

  final leaveTypes = [
    'SICK LEAVE',
    'EMERGENCY LEAVE',
    'OFFICIAL LEAVE',
    'VACATION LEAVE',
    'MATERNITY/PATERNITY LEAVE',
    'OTHERS (PLEASE SPECIFY)',
  ];

  Map<String, bool> selectedLeaveTypes = {
    'SICK LEAVE': false,
    'EMERGENCY LEAVE': false,
    'OFFICIAL LEAVE': false,
    'VACATION LEAVE': false,
    'MATERNITY/PATERNITY LEAVE': false,
    'OTHERS (PLEASE SPECIFY)': false,
  };
  List<String> shiftList = [];
  String? selectedShift;

  String? selectedDepartment;
  bool isAuthenticated = false;
  String selectedRequestType =
      'Request Attendance'; // ✅ This matches a menu item exactly
  String selectedOffset = 'None';

  @override
  void initState() {
    super.initState();
    fetchShifts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAuthPopup();
      }
    });
  }

  @override
  void dispose() {
    offsetDateFromController.dispose();
    offsetDateToController.dispose();
    super.dispose();
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
                searchController.text = username;
                fullNameController.text = fullName; // ✅ set full name here
              });

              await _fetchDepartments(username);
              _fetchAttendanceData();
            },
          ),
    );
  }

  Future<void> fetchShifts() async {
    try {
      final shifts = await attendanceService.fetchShiftSchedules();
      setState(() {
        shiftList = shifts;
        if (shifts.isNotEmpty) selectedShift = shifts[0];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDepartments(String username) async {
    final userService = UserService();
    try {
      final fetchedDepartments = await userService.getUserDepartments(username);
      setState(() {
        departments =
            fetchedDepartments.map<Map<String, String>>((dept) {
              return {
                'DepartmentID': dept['DepartmentID'] as String,
                'DepartmentName': dept['Department'] as String,
              };
            }).toList();

        departmentIds =
            departments.map((dept) => dept['DepartmentID']!).toSet().toList();

        selectedDepartment =
            departmentIds.isNotEmpty ? departmentIds.first : null;

        if (selectedDepartment != null) {
          final department = departments.firstWhere(
            (dept) => dept['DepartmentID'] == selectedDepartment,
            orElse: () => {'DepartmentName': ''},
          );
          departmentNameController.text = department['DepartmentName'] ?? '';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch departments: $e';
      });
    }
  }

  Future<void> _fetchAttendanceData() async {
    final attendanceService = AttendanceService();
    try {
      final data = await attendanceService.fetchAttendanceData();
      setState(() {
        attendanceData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _showEditDialog(dynamic attendance) {
    final timeInController = TextEditingController(text: attendance['TimeIn']);
    final timeOutController = TextEditingController(
      text: attendance['TimeOut'],
    );
    final timeInOTController = TextEditingController(
      text: attendance['TimeIn'],
    );
    final timeOutOTController = TextEditingController(
      text: attendance['TimeOut'],
    );
    final dateController = TextEditingController(
      text: attendance['AttendanceDate'],
    );
    final otHoursController = TextEditingController(
      text: attendance['OverTime'],
    );
    //final otReasonController = TextEditingController();
    final adjustReasonController = TextEditingController();

    final TabController tabController = TabController(
      length: 2,
      vsync: Navigator.of(context),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
              titlePadding: const EdgeInsets.all(12),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Form',
                    style: GoogleFonts.rajdhani(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFFDA1A29),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    controller: tabController,
                    labelColor: const Color(0xFFDA1A29),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: GoogleFonts.rajdhani(
                      fontWeight: FontWeight.bold,
                    ),
                    indicatorColor: const Color(0xFFDA1A29),
                    tabs: const [
                      Tab(text: 'Adjustment'),
                      Tab(text: 'Overtime'),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                height: 300,
                width: 320,
                child: TabBarView(
                  controller: tabController,
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 1),

                          // Shift Schedule Dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(8),
                              shadowColor: Colors.black26,
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Shifting Schedule',
                                  prefixIcon: Icon(
                                    Icons.schedule,
                                    color: Colors.blueAccent,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                iconEnabledColor: Colors.blueAccent,
                                value: selectedShift,
                                items:
                                    shiftList.map((shift) {
                                      return DropdownMenuItem<String>(
                                        value: shift,
                                        child: Text(
                                          shift,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedShift = value!;
                                    // Update other fields if needed
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          _buildTextField(
                            controller: dateController,
                            label: 'Date',
                            icon: Icons.calendar_today,
                            readOnly: true,
                          ),
                          const SizedBox(height: 8),

                          _buildTextField(
                            controller: timeInController,
                            label: 'Time In',
                            icon: Icons.access_time,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                timeInController.text = picked.format(context);
                              }
                            },
                          ),
                          const SizedBox(height: 8),

                          _buildTextField(
                            controller: timeOutController,
                            label: 'Time Out',
                            icon: Icons.access_time,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                timeOutController.text = picked.format(context);
                              }
                            },
                          ),
                          const SizedBox(height: 8),

                          _buildCommentField(
                            controller: adjustReasonController,
                            label: 'Reason',
                            icon: Icons.note_alt,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    // Overtime Tab
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 3),
                          _buildTextField(
                            controller: timeInOTController,
                            label: 'Time In',
                            icon: Icons.access_time,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                timeInOTController.text = picked.format(
                                  context,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: timeOutOTController,
                            label: 'Time Out',
                            icon: Icons.access_time,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                timeOutOTController.text = picked.format(
                                  context,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: otHoursController,
                            label: 'OT Hours',
                            icon: Icons.access_time,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 252, 250, 250),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.rajdhani(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final tabIndex = tabController.index;

                    if (tabIndex == 0) {
                      // Adjustment Submission
                      if (timeInController.text.isEmpty ||
                          timeOutController.text.isEmpty ||
                          adjustReasonController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⛔ Time In/Out and reason required.'),
                          ),
                        );
                        return;
                      }

                      final attendanceID = attendance['AttendanceID'];
                      if (attendanceID == null || attendanceID is! int) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⛔ Invalid Attendance ID'),
                          ),
                        );
                        return;
                      }

                      final updatedAt = DateTime.now();

                      try {
                        await AttendanceService().submitAttendanceForApproval(
                          attendanceID: attendanceID,
                          employeeID: searchController.text.trim(),
                          updateDepartment: selectedDepartment!,
                          timeInRequested: timeInController.text.trim(),
                          timeOutRequested: timeOutController.text.trim(),
                          remarks: adjustReasonController.text.trim(),
                          updatedAt: updatedAt,
                          shiftSchedule:
                              selectedShift, // <-- pass the selected shift here
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        _fetchAttendanceData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Adjustment submitted.'),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
                      }
                    } else {
                      // OT Submission
                      if (timeInOTController.text.isEmpty ||
                          timeOutOTController.text.isEmpty ||
                          otHoursController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '⛔ Time In/Out and OT hours required.',
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        await AttendanceService().requestOvertime(
                          employeeId: searchController.text.trim(),
                          departmentId: selectedDepartment!,
                          date: dateController.text.trim(),
                          timeIn: timeInOTController.text.trim(),
                          timeOut: timeOutOTController.text.trim(),
                          otRequestText: otHoursController.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ OT request submitted.'),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDA1A29),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Submit',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        suffixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildCommentField({
    required TextEditingController controller,
    String label = "Comment",
    IconData icon = Icons.comment,
    int maxLines = 5,
    int maxLength = 500,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      textAlign: TextAlign.start,
      textCapitalization: TextCapitalization.words,
      style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        suffixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 20,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'R E Q U E S T S',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFFDA1A29),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filter the attendance data based on the search query
    List<dynamic> filteredAttendanceData =
        attendanceData.where((attendance) {
          String employeeId = attendance['EmployeeID'] ?? '';
          return employeeId.contains(searchController.text);
        }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFFDA1A29),
        title: Text(
          'R E Q U E S T S',
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
                  const SizedBox(height: 5),
                  // Filters Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFDA1A29),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 3,
                                blurRadius: 8,
                                offset: const Offset(
                                  0,
                                  4,
                                ), // subtle shadow effect
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.black),
                            onPressed: () {
                              final dateController = TextEditingController();
                              final timeInController = TextEditingController();
                              final timeOutController = TextEditingController();
                              final requestAttendanceController =
                                  TextEditingController();
                              final leaveFromController =
                                  TextEditingController();
                              final leaveToController = TextEditingController();
                              final reasonController = TextEditingController();
                              final otherLeaveController =
                                  TextEditingController();

                              DateTime leaveFromDate = DateTime.now();
                              DateTime leaveToDate = DateTime.now();
                              double totalLeaveDays = 1.0;

                              void _computeDays() {
                                if (leaveToDate.isAfter(leaveFromDate) ||
                                    leaveToDate == leaveFromDate) {
                                  totalLeaveDays =
                                      leaveToDate
                                          .difference(leaveFromDate)
                                          .inDays +
                                      1;
                                } else {
                                  totalLeaveDays = 0;
                                }
                              }

                              showDialog(
                                context: context,
                                builder: (context) {
                                  return DefaultTabController(
                                    length: 2,
                                    child: AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      contentPadding: const EdgeInsets.all(20),
                                      titlePadding: const EdgeInsets.all(20),
                                      title: Text(
                                        'Request Form',
                                        style: GoogleFonts.rajdhani(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: const Color(0xFFDA1A29),
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: 320,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const TabBar(
                                                indicatorColor: Color(
                                                  0xFFDA1A29,
                                                ),
                                                labelColor: Color(0xFFDA1A29),
                                                unselectedLabelColor:
                                                    Colors.grey,
                                                tabs: [
                                                  Tab(text: 'Attendance'),
                                                  Tab(text: 'Offset'),
                                                  Tab(text: 'Leave'),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                height:
                                                    300, // Adjust height as needed
                                                child: TabBarView(
                                                  children: [
                                                    // Attendance Tab
                                                    SingleChildScrollView(
                                                      child: Column(
                                                        children: [
                                                          _buildTextField(
                                                            controller:
                                                                dateController,
                                                            label: 'Date',
                                                            icon:
                                                                Icons
                                                                    .calendar_today,
                                                            readOnly: true,
                                                            onTap: () async {
                                                              final picked =
                                                                  await showDatePicker(
                                                                    context:
                                                                        context,
                                                                    initialDate:
                                                                        DateTime.now(),
                                                                    firstDate:
                                                                        DateTime(
                                                                          2000,
                                                                        ),
                                                                    lastDate:
                                                                        DateTime(
                                                                          2100,
                                                                        ),
                                                                  );
                                                              if (picked !=
                                                                  null) {
                                                                dateController
                                                                        .text =
                                                                    DateFormat(
                                                                      'yyyy-MM-dd',
                                                                    ).format(
                                                                      picked,
                                                                    );
                                                              }
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          _buildTextField(
                                                            controller:
                                                                timeInController,
                                                            label: 'Time In',
                                                            icon:
                                                                Icons
                                                                    .access_time,
                                                            readOnly: true,
                                                            onTap: () async {
                                                              final picked =
                                                                  await showTimePicker(
                                                                    context:
                                                                        context,
                                                                    initialTime:
                                                                        TimeOfDay.now(),
                                                                  );
                                                              if (picked !=
                                                                  null) {
                                                                timeInController
                                                                    .text = picked
                                                                    .format(
                                                                      context,
                                                                    );
                                                              }
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          _buildTextField(
                                                            controller:
                                                                timeOutController,
                                                            label: 'Time Out',
                                                            icon:
                                                                Icons
                                                                    .access_time,
                                                            readOnly: true,
                                                            onTap: () async {
                                                              final picked =
                                                                  await showTimePicker(
                                                                    context:
                                                                        context,
                                                                    initialTime:
                                                                        TimeOfDay.now(),
                                                                  );
                                                              if (picked !=
                                                                  null) {
                                                                timeOutController
                                                                    .text = picked
                                                                    .format(
                                                                      context,
                                                                    );
                                                              }
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          _buildCommentField(
                                                            controller:
                                                                requestAttendanceController,
                                                            label: 'Reason',
                                                            icon:
                                                                Icons.note_alt,
                                                            maxLines: 3,
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // Offset Tab
                                                    SingleChildScrollView(
                                                      child: Column(
                                                        children: [
                                                          _buildTextField(
                                                            controller:
                                                                dateController,
                                                            label: 'Date',
                                                            icon:
                                                                Icons
                                                                    .calendar_today,
                                                            readOnly: true,
                                                            onTap: () async {
                                                              final picked =
                                                                  await showDatePicker(
                                                                    context:
                                                                        context,
                                                                    initialDate:
                                                                        DateTime.now(),
                                                                    firstDate:
                                                                        DateTime(
                                                                          2000,
                                                                        ),
                                                                    lastDate:
                                                                        DateTime(
                                                                          2100,
                                                                        ),
                                                                  );
                                                              if (picked !=
                                                                  null) {
                                                                dateController
                                                                        .text =
                                                                    DateFormat(
                                                                      'yyyy-MM-dd',
                                                                    ).format(
                                                                      picked,
                                                                    );
                                                              }
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          _buildCommentField(
                                                            controller:
                                                                requestAttendanceController,
                                                            label: 'Reason',
                                                            icon:
                                                                Icons.note_alt,
                                                            maxLines: 3,
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    //LEAVE Tab
                                                    SingleChildScrollView(
                                                      padding: EdgeInsets.all(
                                                        16,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // Leave From Date Picker
                                                          _buildTextField(
                                                            controller:
                                                                leaveFromController,
                                                            label: 'Leave From',
                                                            icon:
                                                                Icons
                                                                    .calendar_today,
                                                            readOnly: true,
                                                            onTap: () async {
                                                              final picked =
                                                                  await showDatePicker(
                                                                    context:
                                                                        context,
                                                                    initialDate:
                                                                        DateTime.now(),
                                                                    firstDate:
                                                                        DateTime(
                                                                          2000,
                                                                        ),
                                                                    lastDate:
                                                                        DateTime(
                                                                          2100,
                                                                        ),
                                                                  );
                                                              if (picked !=
                                                                  null) {
                                                                leaveFromController
                                                                        .text =
                                                                    DateFormat(
                                                                      'yyyy-MM-dd',
                                                                    ).format(
                                                                      picked,
                                                                    );
                                                                setState(() {
                                                                  leaveFromDate =
                                                                      picked;
                                                                  _computeDays();
                                                                });
                                                              }
                                                            },
                                                          ),

                                                          SizedBox(height: 10),

                                                          // Leave To Date Picker
                                                          _buildTextField(
                                                            controller:
                                                                leaveToController,
                                                            label: 'Leave To',
                                                            icon:
                                                                Icons
                                                                    .calendar_today,
                                                            readOnly: true,
                                                            onTap: () async {
                                                              final picked =
                                                                  await showDatePicker(
                                                                    context:
                                                                        context,
                                                                    initialDate:
                                                                        DateTime.now(),
                                                                    firstDate:
                                                                        DateTime(
                                                                          2000,
                                                                        ),
                                                                    lastDate:
                                                                        DateTime(
                                                                          2100,
                                                                        ),
                                                                  );
                                                              if (picked !=
                                                                  null) {
                                                                leaveToController
                                                                        .text =
                                                                    DateFormat(
                                                                      'yyyy-MM-dd',
                                                                    ).format(
                                                                      picked,
                                                                    );
                                                                setState(() {
                                                                  leaveToDate =
                                                                      picked;
                                                                  _computeDays();
                                                                });
                                                              }
                                                            },
                                                          ),

                                                          SizedBox(height: 10),

                                                          // Total Days Display
                                                          Text(
                                                            'Days: ${totalLeaveDays.toStringAsFixed(2)}',
                                                          ),

                                                          Divider(height: 30),

                                                          Text(
                                                            'Type of Leave',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),

                                                          Wrap(
                                                            spacing: 10,
                                                            children:
                                                                leaveTypes.map((
                                                                  type,
                                                                ) {
                                                                  return Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Checkbox(
                                                                        value:
                                                                            selectedLeaveTypes[type],
                                                                        onChanged: (
                                                                          val,
                                                                        ) {
                                                                          setState(() {
                                                                            selectedLeaveTypes[type] =
                                                                                val!;
                                                                          });
                                                                        },
                                                                      ),
                                                                      Text(
                                                                        type,
                                                                      ),
                                                                    ],
                                                                  );
                                                                }).toList(),
                                                          ),

                                                          if (selectedLeaveTypes['OTHERS (PLEASE SPECIFY)'] ==
                                                              true)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    bottom:
                                                                        12.0,
                                                                  ),
                                                              child: _buildTextField(
                                                                controller:
                                                                    otherLeaveController,
                                                                label:
                                                                    'Specify Other Leave',
                                                                icon:
                                                                    Icons.edit,
                                                              ),
                                                            ),

                                                          _buildCommentField(
                                                            controller:
                                                                reasonController,
                                                            label: 'Reason',
                                                            icon:
                                                                Icons.note_alt,
                                                            maxLines: 3,
                                                          ),

                                                          // SizedBox(height: 20),

                                                          // SizedBox(
                                                          //   width:
                                                          //       double.infinity,
                                                          //   child: ElevatedButton(
                                                          //     onPressed: () {
                                                          //       // Submit handler here
                                                          //     },
                                                          //     style: ElevatedButton.styleFrom(
                                                          //       backgroundColor:
                                                          //           Colors
                                                          //               .blue[700],
                                                          //       padding:
                                                          //           EdgeInsets.symmetric(
                                                          //             vertical:
                                                          //                 15,
                                                          //           ),
                                                          //     ),
                                                          //     child: Text(
                                                          //       'SUBMIT REQUEST',
                                                          //       style: TextStyle(
                                                          //         color:
                                                          //             Colors
                                                          //                 .white,
                                                          //         fontWeight:
                                                          //             FontWeight
                                                          //                 .bold,
                                                          //       ),
                                                          //     ),
                                                          //   ),
                                                          // ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text(
                                            'CANCEL',
                                            style: GoogleFonts.rajdhani(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Builder(
                                          builder: (context) {
                                            // This context is now inside DefaultTabController
                                            return ElevatedButton(
                                              onPressed: () async {
                                                final tabController =
                                                    DefaultTabController.of(
                                                      context,
                                                    );
                                                final selectedTabIndex =
                                                    tabController.index;

                                                if (selectedTabIndex == 0) {
                                                  // Attendance Tab validation
                                                  if (timeInController
                                                          .text
                                                          .isEmpty ||
                                                      timeOutController
                                                          .text
                                                          .isEmpty ||
                                                      requestAttendanceController
                                                          .text
                                                          .isEmpty) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          '⛔ Time In/Out and Reason cannot be empty.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  try {
                                                    await AttendanceService()
                                                        .createAttendance(
                                                          employeeId:
                                                              searchController
                                                                  .text
                                                                  .trim(),
                                                          departmentId:
                                                              selectedDepartment!,
                                                          date:
                                                              dateController
                                                                  .text
                                                                  .trim(),
                                                          timeIn:
                                                              timeInController
                                                                  .text
                                                                  .trim(),
                                                          timeOut:
                                                              timeOutController
                                                                  .text
                                                                  .trim(),
                                                          remarks:
                                                              requestAttendanceController
                                                                  .text
                                                                  .trim(),
                                                        );

                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          '✅ Request attendance submitted successfully!',
                                                        ),
                                                      ),
                                                    );
                                                    Navigator.of(context).pop();
                                                    _fetchAttendanceData();
                                                  } catch (e) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '❌ Error submitting request: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } else {
                                                  // Offset Tab validation
                                                  if (dateController
                                                          .text
                                                          .isEmpty ||
                                                      requestAttendanceController
                                                          .text
                                                          .isEmpty) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          '⛔ Date and Reason cannot be empty.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  try {
                                                    await AttendanceService()
                                                        .createOffset(
                                                          employeeId:
                                                              searchController
                                                                  .text
                                                                  .trim(),
                                                          departmentId:
                                                              selectedDepartment!,
                                                          date:
                                                              dateController
                                                                  .text
                                                                  .trim(),
                                                          remarks:
                                                              requestAttendanceController
                                                                  .text
                                                                  .trim(),
                                                        );

                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          '✅ Offset request submitted successfully!',
                                                        ),
                                                      ),
                                                    );
                                                    Navigator.of(context).pop();
                                                    _fetchAttendanceData();
                                                  } catch (e) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '❌ Error submitting offset: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFDA1A29,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 30,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              child: Text(
                                                'SUBMIT',
                                                style: GoogleFonts.rajdhani(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ), // spacing between add button and fields
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: fullNameController,
                              readOnly: true,
                              decoration: _textFieldDecoration(
                                'Employee Name',
                                Icons.person,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                              style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: DropdownButtonFormField<String>(
                              decoration: _textFieldDecoration(
                                'COST CENTER',
                                Icons.apartment,
                              ),
                              value: selectedDepartment,
                              items:
                                  departments.map((dept) {
                                    final id = dept['DepartmentID'].toString();
                                    final name =
                                        dept['DepartmentName'].toString();
                                    return DropdownMenuItem(
                                      value: id,
                                      child: Text(
                                        name,
                                        style: GoogleFonts.rajdhani(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDepartment = value;
                                });
                              },
                            ),
                          ),
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
                      columns: const [
                        DataColumn2(label: Text('DATE')),
                        DataColumn2(label: Center(child: Text('TIME IN'))),
                        DataColumn2(label: Center(child: Text('LUNCH OUT'))),
                        DataColumn2(label: Center(child: Text('LUNCH IN'))),
                        DataColumn2(label: Center(child: Text('TIME OUT'))),
                        DataColumn2(label: Center(child: Text('ADJUST(+)'))),
                        DataColumn2(label: Center(child: Text('ADJUST(-)'))),
                        DataColumn2(label: Center(child: Text('OVERTIME'))),
                        DataColumn2(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Text('STATUS')],
                          ),
                        ),
                      ],
                      source: _AttendanceDataSource(
                        filteredAttendanceData,
                        _showEditDialog,
                      ),
                      rowsPerPage: 15,
                      showCheckboxColumn: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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

InputDecoration _textFieldDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.rajdhani(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    prefixIcon: Icon(icon, color: Colors.red),
    filled: true,
    fillColor: const Color.fromARGB(255, 241, 240, 240),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  );
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
        SizedBox(width: 8),
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
  final Function(dynamic) onRowTap;

  _AttendanceDataSource(this.attendanceData, this.onRowTap);

  @override
  DataRow? getRow(int index) {
    if (index >= attendanceData.length) return null;
    final attendance = attendanceData[index];

    // Get prioritized TimeIn and TimeOut for long press
    String prioritizedTimeIn =
        (attendance['TimeInA'] != null &&
                attendance['TimeInA'].toString().trim().isNotEmpty)
            ? attendance['TimeInA']
            : (attendance['TimeIn'] ?? '');

    String prioritizedTimeOut =
        (attendance['TimeOutA'] != null &&
                attendance['TimeOutA'].toString().trim().isNotEmpty)
            ? attendance['TimeOutA']
            : (attendance['TimeOut'] ?? '');

    return DataRow(
      onLongPress:
          () => onRowTap({
            ...attendance,
            'TimeIn': prioritizedTimeIn,
            'TimeOut': prioritizedTimeOut,
          }),
      cells: [
        DataCell(Text(attendance['AttendanceDate'] ?? '')),
        DataCell(Center(child: Text(attendance['TimeIn'] ?? ''))),
        DataCell(Center(child: Text(attendance['LunchOut'] ?? ''))),
        DataCell(Center(child: Text(attendance['LunchIn'] ?? ''))),
        DataCell(Center(child: Text(attendance['TimeOut'] ?? ''))),
        DataCell(Center(child: Text(attendance['TimeInA'] ?? ''))),
        DataCell(Center(child: Text(attendance['TimeOutA'] ?? ''))),
        DataCell(
          Center(
            child: Text(
              (attendance['OverTime'] == null ||
                      attendance['OverTime'] == '.00' ||
                      attendance['OverTime'].toString().trim().isEmpty)
                  ? '---N/A---'
                  : attendance['OverTime'],
              style: TextStyle(
                color:
                    (attendance['OverTime'] == null ||
                            attendance['OverTime'] == '.00' ||
                            attendance['OverTime'].toString().trim().isEmpty)
                        ? Colors.grey
                        : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),

        // Apply color to the Status column based on the status value
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (attendance['Status'] == 'FAP')
                Container(
                  width: 15.0,
                  height: 15.0,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                )
              else if (attendance['Status'] == 'L')
                Container(
                  width: 15.0,
                  height: 15.0,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 243, 229, 30),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                )
              else if (attendance['Status'] == 'C' ||
                  attendance['Status'] == 'REST DAY')
                Container(
                  width: 15.0,
                  height: 15.0,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                )
              else if (attendance['Status'] == 'NL')
                Container(
                  width: 15.0,
                  height: 15.0,
                  decoration: BoxDecoration(
                    color: Colors.lightGreenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                )
              else
                Text(
                  attendance['Status'] ?? '',
                  style: TextStyle(
                    color: _getStatusColor(attendance['Status']),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'NL':
        return Colors.yellowAccent; // Yellow-Green for NL
      default:
        return Colors.black; // Default color if status doesn't match
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => attendanceData.length;

  @override
  int get selectedRowCount => 0;
}
