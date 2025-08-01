// ignore_for_file: use_build_context_synchronously

import 'package:data_table_2/data_table_2.dart';
import 'package:dtr_app/pages/auth_popup_page.dart';
import 'package:dtr_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dtr_app/services/shift_service.dart';

class AssignShiftPage extends StatefulWidget {
  const AssignShiftPage({super.key});

  @override
  State<AssignShiftPage> createState() => _AssignShiftPageState();
}

class _AssignShiftPageState extends State<AssignShiftPage> {
  // Controllers
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController departmentIdController = TextEditingController();
  final TextEditingController departmentNameController =
      TextEditingController();

  // State variables
  String? selectedEmployeeName;
  String? selectedShift;
  String? selectedDepartment;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  List<Map<String, dynamic>> fetchedDepartments =
      []; // Store fetched departments

  List<Map<String, dynamic>> assignedShifts = [];
  List<Map<String, dynamic>> employeeList = [];
  List<Map<String, dynamic>> filteredEmployeeList = [];
  List<String> departmentIds = [];

  final List<String> shifts = [
    'REGULAR SHIFT',
    'AFTERNOON SHIFT',
    'NIGHT SHIFT',
    'REST DAY',
  ];

  final ShiftService _shiftService = ShiftService();
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

  // Authentication popup
  void _showAuthPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AuthPopupPage(
            onAuthenticated: (String username, String fullName) async {
              await _fetchDepartments(
                username,
              ); // Fetch departments for the user
              fetchAssignedShifts(); // Fetch assigned shifts
              fetchEmployees(); // Fetch employee data
            },
          ),
    );
  }

  // Fetch departments based on the authenticated username
  Future<void> _fetchDepartments(String username) async {
    try {
      final departments = await _userService.getUserDepartments(username);
      setState(() {
        fetchedDepartments = departments; // Store fetched departments
        departmentIds =
            departments
                .map((dept) => dept['DepartmentID'] as String)
                .toSet() // Ensure unique values
                .toList();

        // Set selectedDepartment to the first department in the list
        selectedDepartment =
            departmentIds.isNotEmpty ? departmentIds.first : null;

        // Update the department name if a department is selected
        if (selectedDepartment != null) {
          final department = departments.firstWhere(
            (dept) => dept['DepartmentID'] == selectedDepartment,
            orElse: () => {'Department': ''},
          );
          departmentNameController.text = department['Department'] ?? '';
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text('Failed to fetch departments: $e'),
        ),
      );
    }
  }

  // Fetch employee data
  Future<void> fetchEmployees() async {
    try {
      final employees = await _shiftService.fetchEmployees();
      setState(() {
        employeeList =
            employees; // Ensure employees have 'name', 'id', and 'departmentId'
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text('Error fetching employee data: $e'),
        ),
      );
    }
  }

  // Fetch assigned shifts
  Future<void> fetchAssignedShifts() async {
    try {
      final shifts = await _shiftService.fetchAssignedShifts();
      setState(() {
        assignedShifts = shifts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text('Error fetching assigned shifts: $e'),
        ),
      );
    }
  }

  // Save shift
  Future<void> saveShift({
    required BuildContext context,
    required String employeeId,
    required String departmentId,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String shiftType,
  }) async {
    try {
      final now = DateTime.now();

      final shiftStart = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      // If endTime is earlier than startTime, assume shift ends the next day (overnight shift)
      final shiftEnd = DateTime(
        now.year,
        now.month,
        now.day + (endTime.hour < startTime.hour ? 1 : 0),
        endTime.hour,
        endTime.minute,
      );

      final response = await _shiftService.saveShift(
        employeeId: employeeId,
        departmentId: departmentId,
        shiftStart: shiftStart.toIso8601String(),
        shiftEnd: shiftEnd.toIso8601String(),
        shiftType: shiftType,
      );

      if (response.containsKey('status')) {
        // ✅ Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              response['status'],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      } else if (response.containsKey('error')) {
        // ❌ Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[800],
            content: Text(
              response['error'],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      } else {
        // 🤔 Unexpected format
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.black87,
            content: Text('Unexpected server response.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text('Error saving shift: $e'),
        ),
      );
    }
  }

  // Assign shift
  void assignShift() async {
    if (selectedEmployeeName != null &&
        selectedShift != null &&
        startTime != null &&
        endTime != null) {
      try {
        final formattedStartTime = formatTime(startTime!);
        final formattedEndTime = formatTime(endTime!);

        // Add to local UI list for display
        setState(() {
          assignedShifts.add({
            'employee': selectedEmployeeName,
            'shift': selectedShift,
            'start': formattedStartTime,
            'end': formattedEndTime,
          });
        });

        // Call backend save
        await saveShift(
          context: context,
          employeeId: employeeIdController.text,
          departmentId: departmentIdController.text,
          startTime: startTime!,
          endTime: endTime!,
          shiftType: selectedShift!,
        );

        // Reset form fields after saving
        setState(() {
          selectedEmployeeName = null;
          selectedShift = null;
          startTime = null;
          endTime = null;
          employeeIdController.clear();
          departmentIdController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[800],
            content: Text('Error assigning shift: $e'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black87,
          content: Text('Please complete all required fields.'),
        ),
      );
    }
  }

  // Format time
  String formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  // Pick time
  Future<void> pickTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStart
              ? const TimeOfDay(hour: 6, minute: 0)
              : const TimeOfDay(hour: 15, minute: 0),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        title: Text(
          'S H I F T   A S S I G N M E N T',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
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
        backgroundColor: const Color(0xFFDA1A29),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Department dropdown (combined ID + name)
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Cost Center',
                      labelStyle: GoogleFonts.rajdhani(color: Colors.black87),
                      prefixIcon: const Icon(
                        Icons.apartment,
                        color: Colors.red,
                      ),
                      filled: true,
                      fillColor: Color.fromARGB(
                        255,
                        230,
                        230,
                        230,
                      ), // 🔘 Light grey background
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                    value: selectedDepartment,
                    items:
                        fetchedDepartments.map((dept) {
                          final id = dept['DepartmentID'].toString();
                          final name = dept['Department'].toString();
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(
                              '$id - $name',
                              style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDepartment = value ?? '';
                        selectedEmployeeName = null;
                        employeeIdController.clear();
                        departmentIdController.clear();
                        selectedShift = null;

                        final department = fetchedDepartments.firstWhere(
                          (dept) =>
                              dept['DepartmentID'].toString() ==
                              selectedDepartment,
                          orElse: () => {'Department': ''},
                        );
                        departmentNameController.text =
                            department['Department'] ?? '';

                        filteredEmployeeList =
                            employeeList
                                .where(
                                  (emp) =>
                                      emp['departmentId'] == selectedDepartment,
                                )
                                .toList();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Employee',
                      labelStyle: GoogleFonts.rajdhani(color: Colors.black87),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Colors.red,
                      ),
                      filled: true,
                      fillColor: Color.fromARGB(
                        255,
                        230,
                        230,
                        230,
                      ), // 🔘 Light grey background
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                    value: selectedEmployeeName,
                    items:
                        filteredEmployeeList.map((emp) {
                          return DropdownMenuItem<String>(
                            value: emp['name'],
                            child: Text(
                              emp['name'],
                              style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedEmployeeName = value;

                        final selectedEmp = filteredEmployeeList.firstWhere(
                          (emp) => emp['name'] == selectedEmployeeName,
                          orElse: () => {},
                        );

                        employeeIdController.text = selectedEmp['id'] ?? '';
                        departmentIdController.text =
                            selectedEmp['departmentId'] ?? '';
                        departmentNameController.text =
                            fetchedDepartments.firstWhere(
                              (dept) =>
                                  dept['DepartmentID'].toString() ==
                                  selectedEmp['departmentId'],
                              orElse: () => {'Department': ''},
                            )['Department'] ??
                            '';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            // Shift dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Shift Type',
                labelStyle: GoogleFonts.rajdhani(color: Colors.black87),
                prefixIcon: const Icon(
                  Icons.schedule,
                  color: Colors.red,
                ), // ⏰ Icon
                filled: true,
                fillColor: Color.fromARGB(
                  255,
                  230,
                  230,
                  230,
                ), // 🔘 Light grey background
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ), // 🔴 Red border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              value: selectedShift,
              items:
                  shifts.map((shift) {
                    return DropdownMenuItem<String>(
                      value: shift,
                      child: Text(
                        shift,
                        style: GoogleFonts.rajdhani(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedShift = value;
                });
              },
            ),

            const SizedBox(height: 5),
            // Time picking buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickTime(isStart: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 241, 241, 238),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Colors.white,
                        width: 2,
                      ), // 🔴
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Optional: rounded corners
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          startTime == null
                              ? 'SHIFT START'
                              : 'START: ${formatTime(startTime)}',
                          style: GoogleFonts.rajdhani(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickTime(isStart: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 241, 241, 238),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Colors.white,
                        width: 2,
                      ), // 🔴 Red border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          endTime == null
                              ? 'SHIFT END'
                              : 'END: ${formatTime(endTime)}',
                          style: GoogleFonts.rajdhani(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Assign shift button
            Center(
              child: ElevatedButton.icon(
                onPressed: assignShift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 201, 34, 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 150,
                    vertical: 12,
                  ),
                  side: const BorderSide(
                    color: Colors.black,
                    width: 2,
                  ), // 🔴 Red border
                ),
                icon: const Icon(
                  Icons.save_as,
                  color: Colors.white,
                  size: 22,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                label: Text(
                  'SAVE SHIFT',
                  style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
              ),
            ),
            Text(
              'ASSIGNED LIST',
              style: GoogleFonts.rajdhani(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 7, 7, 7),
                textStyle: TextStyle(
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: const Offset(1, 0),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 1),
            const Divider(color: Colors.black26, thickness: 1, height: 3),

            // Assigned employees table
            const SizedBox(height: 1),
            Expanded(
              child:
                  assignedShifts.isEmpty
                      ? Center(
                        child: Text(
                          'No assigned shifts yet.',
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      )
                      : DataTable2(
                        columnSpacing: 20,
                        horizontalMargin: 12,
                        headingRowHeight: 25,
                        dataRowHeight: 30,
                        minWidth: 700,
                        headingRowColor: WidgetStateProperty.all(
                          const Color.fromARGB(
                            255,
                            218,
                            39,
                            26,
                          ).withOpacity(0.9),
                        ),
                        headingTextStyle: GoogleFonts.rajdhani(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        dataTextStyle: GoogleFonts.rajdhani(
                          fontSize: 10,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        columns: const [
                          DataColumn(label: Text('EMPLOYEE')),
                          DataColumn(label: Text('SHIFT TYPE')),
                          DataColumn(label: Center(child: Text('SHIFT START'))),
                          DataColumn(label: Center(child: Text('SHIFT END'))),
                        ],
                        rows:
                            assignedShifts
                                .where((shift) {
                                  final emp = employeeList.firstWhere(
                                    (e) => e['name'] == shift['employee'],
                                    orElse: () => {},
                                  );
                                  return emp['departmentId'] ==
                                      selectedDepartment;
                                })
                                .map((shift) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(shift['employee'] ?? '')),
                                      DataCell(Text(shift['shift'] ?? '')),
                                      DataCell(
                                        Center(
                                          child: Text(shift['start'] ?? ''),
                                        ),
                                      ),
                                      DataCell(
                                        Center(child: Text(shift['end'] ?? '')),
                                      ),
                                    ],
                                  );
                                })
                                .toList(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
