// ignore_for_file: use_build_context_synchronously

import 'package:dtr_app/pages/auth_popup_page.dart';
import 'package:dtr_app/services/division_service.dart';
import 'package:dtr_app/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dtr_app/services/shift_service.dart';

class DivisionPage extends StatefulWidget {
  const DivisionPage({super.key});

  @override
  State<DivisionPage> createState() => _DivisionPageState();
}

class _DivisionPageState extends State<DivisionPage> {
  // Controllers
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController departmentIdController = TextEditingController();
  final TextEditingController departmentNameController =
      TextEditingController();
  final TextEditingController workInfoIdController = TextEditingController();

  // State variables
  String? selectedEmployeeName;
  String? selectedShift;
  String? selectedDepartment;
  String? selectedNewDepartment;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  List<Map<String, dynamic>> fetchedDepartments =
      []; // Store fetched departments

  List<Map<String, dynamic>> assignedShifts = [];
  List<Map<String, dynamic>> employeeList = [];
  List<Map<String, dynamic>> filteredEmployeeList = [];
  List<String> departmentIds = [];

  final List<String> shifts = [
    'ACTIVE',
    'INACTIVE',
    'ON LEAVE',
    'SUSPENDED',
    'RESIGNED',
    'TERMINATED',
    'RETIRED',
  ];

  final ShiftService _shiftService = ShiftService();
  final UserService _userService = UserService();
  final DivisionService _divisionService = DivisionService();

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
              await _fetchDepartments(username);
              fetchEmployees(); // Fetch employee data
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

        if (selectedDepartment != null) {
          final department = departments.firstWhere(
            (dept) => dept['DepartmentID'] == selectedDepartment,
            orElse: () => {'Department': ''},
          );
          departmentNameController.text = department['Department'] ?? '';
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching departments: $e');
      } // Added error print
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        employeeList = employees;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching employee data: $e');
      } // Added error print
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text('Error fetching employee data: $e'),
        ),
      );
    }
  }

  // Save shift
  Future<void> saveChanges({
    required String employeeId,
    required String workInfoId,
    required String departmentId,
    required String workStatus,
  }) async {
    try {
      final result = await _divisionService.saveChanges(
        employeeId: employeeId,
        workInfoId: workInfoId,
        departmentId: departmentId,
        workStatus: workStatus,
      );
      if (!mounted) return;

      // Check if the response contains the expected success key or error message
      if (result['error'] != null) {
        // Display the error message if present
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black87,
            content: Text('Error: ${result['error']}'),
          ),
        );
      } else {
        if (result['success'] == true) {
          // If the update was successful, show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFB3202D),
              content: Text(
                result['message'],
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        } else {
          // Handle unexpected response format
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.black87,
              content: Text('Unexpected response format: $result'),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving shift: $e');
      } // Added error print
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text('Error saving shift: $e'),
        ),
      );
    }
  }

  // Assign shift
  void updateDivision() async {
    if (selectedEmployeeName != null) {
      if (employeeIdController.text.isEmpty ||
          workInfoIdController.text.isEmpty ||
          (selectedNewDepartment ?? selectedDepartment) == null ||
          selectedShift == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.black87,
            content: Text('Please complete all required fields.'),
          ),
        );
        return;
      }

      try {
        setState(() {
          assignedShifts.add({
            'employeeid': employeeIdController.text,
            'workinfoid': workInfoIdController.text,
            'departmentid': selectedNewDepartment ?? selectedDepartment,
            'workstatus': selectedShift,
          });
        });

        await saveChanges(
          employeeId: employeeIdController.text,
          workInfoId: workInfoIdController.text,
          departmentId: selectedNewDepartment ?? selectedDepartment!,
          workStatus: selectedShift!,
        );

        // Reset UI and fetch fresh employee data
        setState(() {
          selectedEmployeeName = null;
          employeeIdController.clear();
          workInfoIdController.clear();
          departmentIdController.clear();
          selectedNewDepartment = null;
          selectedShift = null;
          fetchEmployees();
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error assigning shift: $e');
        } // Added error print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black87,
            content: Text('Error assigning shift: ${e.toString()}'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black87,
          content: Text('Please select an employee'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        title: Text(
          'D I V I S I O N',
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Department dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Cost Center',
                      labelStyle: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
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
                    value:
                        departmentIds.contains(selectedDepartment)
                            ? selectedDepartment
                            : null,
                    items:
                        fetchedDepartments.map((dept) {
                          final departmentId = dept['DepartmentID'].toString();
                          return DropdownMenuItem<String>(
                            value: departmentId,
                            child: Text(
                              "$departmentId - ${dept['Department']}",
                              style: GoogleFonts.rajdhani(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDepartment = value;

                        // Clear employee selection and text fields
                        selectedEmployeeName = null;
                        employeeIdController.clear();
                        departmentIdController.clear();
                        selectedShift = null;

                        // Update the department name
                        final department = fetchedDepartments.firstWhere(
                          (dept) => dept['DepartmentID'] == selectedDepartment,
                          orElse: () => {'Department': ''},
                        );
                        departmentNameController.text =
                            department['Department'] ?? '';

                        // Filter employees based on the selected department
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
                const SizedBox(width: 5),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Employee',
                      labelStyle: GoogleFonts.rajdhani(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      prefixIcon: const Icon(
                        Icons.person_rounded,
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
                            departmentNameController.text =
                                fetchedDepartments.firstWhere(
                                  (dept) =>
                                      dept['DepartmentID'] ==
                                      selectedEmp['departmentId'],
                                  orElse: () => {'Department': ''},
                                )['Department'] ??
                                '';
                        workInfoIdController.text = selectedEmp['workId'] ?? '';
                        selectedShift = selectedEmp['workstatus'] ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),

            if (selectedEmployeeName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                      controller: workInfoIdController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Work ID',
                        labelStyle: GoogleFonts.rajdhani(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
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
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                      controller: employeeIdController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Employee ID',
                        labelStyle: GoogleFonts.rajdhani(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Transfer to:',
                  labelStyle: GoogleFonts.rajdhani(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: const Icon(
                    Icons.departure_board,
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
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                value: selectedNewDepartment,
                items:
                    fetchedDepartments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept['DepartmentID'],
                        child: Text(
                          "${dept['DepartmentID']} - ${dept['Department']}",
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedNewDepartment = value;
                  });
                },
              ),
            ],

            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS',
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: '',
                labelStyle: GoogleFonts.rajdhani(color: Colors.black87),
                filled: true,
                fillColor: _getStatusColor(
                  selectedShift,
                ), // Dynamic background color

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 2,
                  ), // Default border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 2,
                  ), // Unfocused
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 2,
                  ), // Focused
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
                          color: Colors.black,
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

            // Helper function to determine the background color based on the selected status
            const SizedBox(height: 5),

            // Save button
            _buildActionButton(
              "SAVE",
              () => updateDivision(),
              const Color.fromARGB(255, 228, 28, 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green; // Green for ACTIVE
      case 'SUSPENDED':
        return Colors.orange; // Orange for SUSPENDED
      case 'INACTIVE':
        return const Color.fromARGB(255, 187, 33, 21); // Orange for SUSPENDED
      default:
        return Colors
            .white; // Default background color if no status or other status
    }
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.save, size: 18),
              const SizedBox(width: 5),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
