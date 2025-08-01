// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:dtr_app/components/camera_section.dart';
import 'package:dtr_app/components/clock_section.dart';
import 'package:dtr_app/components/empid_textfield.dart';
import 'package:dtr_app/components/handle_action_buttons.dart';
import 'package:dtr_app/components/my_logo.dart';
import 'package:dtr_app/components/name_textfield.dart';
import 'package:dtr_app/components/user_section.dart';
import 'package:dtr_app/pages/approval_page.dart';
import 'package:dtr_app/pages/assign_shift_page.dart';
import 'package:dtr_app/pages/attendance_log_page.dart';
import 'package:dtr_app/pages/auth_page.dart';
import 'package:dtr_app/pages/division_page.dart';
import 'package:dtr_app/pages/offline_page.dart';
import 'package:dtr_app/pages/time_adjustment_page.dart';
import 'package:dtr_app/services/attendance_offline_services.dart';
import 'package:dtr_app/services/attendance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _idnumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmetidController = TextEditingController();

  bool? hasTimeIn = true;
  bool? hasLunchOut;
  bool? hasLunchIn;
  bool? hasTimeOut;
  bool _showCamera = false;
  bool _isOnline = false; // NEW: track online status

  String? timeIn, timeOut, breakOut, breakIn;
  String _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
  Timer? _timer;
  String? _snackBarMessage;
  Color? _snackBarColor;

  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  User? user = FirebaseAuth.instance.currentUser;

  List<dynamic> _recentLogs = [];
  bool _wasOnline = false;

  final double geofenceLatitude = 7.114448010081642;
  final double geofenceLongitude = 125.6227766097625;
  final double geofenceRadius = 25000; // in meters

  @override
  void initState() {
    super.initState();
    _startClock();
    _fetchRecentLogs();
    _fetchAttendanceData(_idnumberController.text);
    _checkOnlineStatus();

    // Try syncing on app start if online
    // We add a delay to ensure everything is initialized before syncing
    Future.delayed(Duration(seconds: 1), () async {
      if (_isOnline) {
        await OfflineStorageService.syncPendingEntries();
        _fetchRecentLogs();
      }
    });

    Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkOnlineStatus();
      _fetchRecentLogs();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _idnumberController.dispose();

    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
        });
      }
    });
  }

  Future<void> _checkOnlineStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'http://panaderooffice.ddns.net:8080/DTRApi/api/ping.php',
            ),
          )
          .timeout(const Duration(seconds: 5));

      bool currentlyOnline = response.statusCode == 200;

      if (mounted) {
        setState(() => _isOnline = currentlyOnline);
      }

      // Sync only if going from offline to online
      if (!_wasOnline && currentlyOnline) {
        await OfflineStorageService.syncPendingEntries();
        _fetchRecentLogs();
      }

      _wasOnline = currentlyOnline;
    } catch (_) {
      if (mounted) setState(() => _isOnline = false);
      _wasOnline = false;
    }
  }

  // void _navigateToOfflinePage() {
  //   Future.delayed(Duration.zero, () {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const OfflineRecordsPage()),
  //     );
  //   });
  // }

  void _fetchAttendanceData(String employeeId) async {
    final url =
        'http://panaderooffice.ddns.net:8080/DTRApi/api/get_attendance_today.php?employee_id=$employeeId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          setState(() {
            _nameController.text = data[0]['full_name'] ?? '';
            _departmetidController.text = data[0]['department_id'] ?? '';
            hasTimeIn = data[0]['time_in'] != null && data[0]['time_in'] != "";
            hasLunchOut =
                data[0]['lunch_out'] != null && data[0]['lunch_out'] != "";
            hasLunchIn =
                data[0]['lunch_in'] != null && data[0]['lunch_in'] != "";
            hasTimeOut =
                data[0]['time_out'] != null && data[0]['time_out'] != "";
          });
        } else {
          // No data returned – treat it as no attendance yet
          setState(() {
            _nameController.clear(); // Clear the name field
            hasTimeIn = false;
            hasLunchOut = false;
            hasLunchIn = false;
            hasTimeOut = false;
          });
        }
      } else {
        // Error response from server
        setState(() {
          hasTimeIn = false;
          hasLunchOut = false;
          hasLunchIn = false;
          hasTimeOut = false;
        });
      }
    } catch (error) {
      // Network or decoding error
      setState(() {
        hasTimeIn = false;
        hasLunchOut = false;
        hasLunchIn = false;
        hasTimeOut = false;
      });
    }
  }

  String getCurrentTime() => DateFormat('hh:mm a').format(DateTime.now());

  Future<bool> _isWithinGeofence(String departmentId) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showSnackBar("Location service disabled", Colors.red);
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackBar("Location permission denied", Colors.red);
        return false;
      }

      // 🔁 Fetch all departments
      final response = await http.get(
        Uri.parse(
          'http://panaderooffice.ddns.net:8080/DTRApi/api/get_department.php',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        _showSnackBar("❌ Failed to fetch departments", Colors.red);
        return false;
      }

      final List<dynamic> departments = jsonDecode(response.body);
      final dept = departments.firstWhere(
        (d) => d['DepartmentID'] == departmentId,
        orElse: () => null,
      );

      if (dept == null) {
        _showSnackBar("❌ Department geofence not found", Colors.red);
        return false;
      }

      double lat = double.tryParse(dept['Latitude']) ?? 0.0;
      double lng = double.tryParse(dept['Longtitude']) ?? 0.0;
      double radius = double.tryParse(dept['Meter']) ?? 25.0;

      // 🔁 Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lng,
      );

      return distance <= radius;
    } catch (e) {
      debugPrint("Geofence check error: $e");
      _showSnackBar("❌ Geofence check error", Colors.red);
      return false;
    }
  }

  Future<void> _handleAction(
    String label,
    Function(String) onCaptureSuccess,
    String apiUrl,
  ) async {
    final idNumber = _idnumberController.text.trim();
    final deptId = _departmetidController.text.trim();

    if (idNumber.isEmpty) {
      _showSnackBar("❌ Enter ID number", Colors.red);
      return;
    }

    if (_isOnline) {
      final isInsideGeofence = await _isWithinGeofence(deptId);
      if (!isInsideGeofence) {
        _showSnackBar("❌ You are outside the attendance area", Colors.red);
        return;
      }
    }

    CameraController? cameraController;
    XFile? capturedPhoto;

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController.initialize();

      setState(() {
        _controller = cameraController;
        _isCameraInitialized = true;
        _showCamera = true;
      });

      await Future.delayed(const Duration(seconds: 1));
      capturedPhoto = await cameraController.takePicture();
      await cameraController.dispose();

      setState(() {
        _isCameraInitialized = false;
        _controller = null;
        _showCamera = false;
      });
    } catch (e) {
      _showSnackBar("❌ Camera error: ${e.toString()}", Colors.red);
      return;
    }

    final now = getCurrentTime();
    final bytes = await capturedPhoto.readAsBytes();
    final base64Image = base64Encode(bytes);

    try {
      final attendanceService = AttendanceService();
      final result = await attendanceService.handleAction(
        label: label,
        idNumber: idNumber,
        apiUrl: apiUrl,
        currentTime: now,
        photoBase64: base64Image,
      );

      if (result['success'] == true) {
        _fetchRecentLogs();
        onCaptureSuccess(now);
        _showSnackBar("✅ ${result['message'] ?? 'Success'}", Colors.green);
      } else {
        _showSnackBar("❌ ${result['message'] ?? 'Action failed'}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("❌ Failed to sync. Try again later.", Colors.red);
    }

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _recentLogs.clear());
    });

    _idnumberController.clear();
    _nameController.clear();
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      setState(() {
        _snackBarMessage = message;
        _snackBarColor = color;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _snackBarMessage = null;
            _snackBarColor = null;
          });
        }
      });
    }
  }

  Future<void> _fetchRecentLogs() async {
    try {
      final attendanceService = AttendanceService();
      final logs = await attendanceService.fetchRecentLogs(
        _idnumberController.text,
      );
      if (mounted) {
        setState(() {
          _recentLogs = logs;
        });
      }
    } catch (e) {}
  }

  Widget _buildSnackBar() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4, // Center-ish vertically
      left: 20,
      right: 20,
      child: Visibility(
        visible: _snackBarMessage != null,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          color: _snackBarColor ?? Colors.black87,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _snackBarMessage ?? '',
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
    );
  }

  void signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFFF8F0),
            title: Text(
              "Sign Out?",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: const Color(0xFFDA1A29),
              ),
            ),
            content: Text(
              "Are you sure you want to leave the oven this soon?",
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                color: Colors.brown[600],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(foregroundColor: Colors.brown[400]),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFDA1A29),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    // Safely handle null or false
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:
          _showCamera
              ? null
              : _buildDrawer(), // disable drawer when camera open
      appBar:
          _showCamera ? null : _buildAppBar(), // hide app bar when camera open
      body: SafeArea(
        child:
            _showCamera && _isCameraInitialized
                ? CameraSection(
                  isCameraInitialized: _isCameraInitialized,
                  controller: _controller!,
                )
                : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          UserSection(),
                          const SizedBox(height: 5),
                          ClockSection(currentTime: _currentTime),
                          const SizedBox(height: 1),
                          // No camera here because it's fullscreen when open
                          _nameController.text.isNotEmpty
                              ? NameTextField(controller: _nameController)
                              : SizedBox.shrink(),
                          const SizedBox(height: 5),
                          _buildTextField(),
                          const SizedBox(height: 5),
                          if (_idnumberController.text.isNotEmpty &&
                              (hasTimeIn == false ||
                                  hasLunchIn == false ||
                                  hasLunchOut == false ||
                                  hasTimeOut == false ||
                                  _recentLogs.isEmpty))
                            ActionButtons(
                              handleAction: _handleAction,
                              onViewAttendanceLog: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AttendanceLogPage(),
                                  ),
                                );
                              },
                              hasTimeIn: hasTimeIn ?? false,
                              hasLunchIn: hasLunchIn ?? false,
                              hasLunchOut: hasLunchOut ?? false,
                              hasTimeOut: hasTimeOut ?? false,
                              hasAttendanceData:
                                  hasTimeIn == true ||
                                  hasLunchIn == true ||
                                  hasLunchOut == true ||
                                  hasTimeOut == true,
                              apiResponse: _recentLogs,
                            ),
                          const SizedBox(height: 5),
                          SizedBox(
                            height: 200,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  color: const Color.fromARGB(
                                    255,
                                    238,
                                    236,
                                    235,
                                  ),

                                  child: Row(
                                    children: [
                                      _buildHeaderCell('TIME IN'),
                                      _buildHeaderCell('LUNCH OUT'),
                                      _buildHeaderCell('LUNCH IN'),
                                      _buildHeaderCell('TIME OUT'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _recentLogs.length,
                                    itemBuilder: (context, index) {
                                      final log = _recentLogs[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7EC),
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.brown.shade100,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            _buildDataCell(
                                              '${log['TimeIn'] ?? ''}',
                                            ),
                                            _buildDataCell(
                                              '${log['LunchOut'] ?? ''}',
                                            ),
                                            _buildDataCell(
                                              '${log['LunchIn'] ?? ''}',
                                            ),
                                            _buildDataCell(
                                              '${log['TimeOut'] ?? ''}',
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSnackBar(),
                  ],
                ),
      ),
    );
  }

  Widget _buildHeaderCell(String label) {
    return Expanded(
      flex: 1,
      child: Text(
        label,
        style: GoogleFonts.rajdhani(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String? value) {
    return Expanded(
      flex: 1,
      child: Text(
        value ?? '',
        style: GoogleFonts.rajdhani(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // AppBar
  AppBar _buildAppBar() {
    return AppBar(
      toolbarHeight: 40, // Increased to accommodate two lines
      backgroundColor: const Color(0xFFDA1A29),
      centerTitle: true,
      iconTheme: const IconThemeData(
        color: Colors.white, // Drawer icon color
      ),
      title: Row(
        children: [
          Text(
            'PANADERO TIME TRACKER',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isOnline ? 'ONLINE' : 'OFFLINE',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Footer at the bottom
        children: [
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Drawer Header
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFFDA1A29), // Panadero red
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: MyLogo(), // Your custom logo widget
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.email ?? 'Guest User',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Welcome to Panadero!',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Image.asset(
                          'lib/images/Panadero.png',
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items
                ListTile(
                  leading: const Icon(Icons.dashboard), // Changed from home
                  title: Text(
                    'H O M E',
                    style: GoogleFonts.alegreya(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                if (user?.email != 'panadero_dtr@gmail.com')
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_month,
                    ), // Changed from schedule
                    title: Text(
                      'S H I F T',
                      style: GoogleFonts.alegreya(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AssignShiftPage(),
                        ),
                      );
                    },
                  ),
                if (user?.email != 'panadero_dtr@gmail.com')
                  ListTile(
                    leading: const Icon(
                      Icons.list_alt,
                    ), // Changed from assignment
                    title: Text(
                      'L O G S',
                      style: GoogleFonts.alegreya(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceLogPage(),
                        ),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.edit_calendar,
                  ), // Changed from remove_from_queue
                  title: Text(
                    'R E Q U E S T',
                    style: GoogleFonts.alegreya(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TimeAdjustmentPage()),
                    );
                  },
                ),
                if (user?.email != 'panadero_dtr@gmail.com')
                  ListTile(
                    leading: const Icon(
                      Icons.verified,
                    ), // Changed from approval
                    title: Text(
                      'A P P R O V A L',
                      style: GoogleFonts.alegreya(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceApprovalPage(),
                        ),
                      );
                    },
                  ),
                if (user?.email != 'panadero_dtr@gmail.com')
                  if (user?.email != 'panadero_tl@gmail.com')
                    ListTile(
                      leading: const Icon(
                        Icons.account_tree,
                      ), // Changed from business_center_rounded
                      title: Text(
                        'D I V I S I O N',
                        style: GoogleFonts.alegreya(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DivisionPage(),
                          ),
                        );
                      },
                    ),

                const Divider(),

                 ListTile(
                      leading: const Icon(
                        Icons.account_tree,
                      ), // Changed from business_center_rounded
                      title: Text(
                        'O F F L I N E',
                        style: GoogleFonts.alegreya(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>  OfflineAttendanceManualPage(),
                          ),
                        );
                      },
                    ),

                ListTile(
                  leading: const Icon(Icons.exit_to_app), // Updated icon
                  title: Text(
                    'S I G N  O U T',
                    style: GoogleFonts.alegreya(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    signOut(context);
                  },
                ),
              ],
            ),
          ),
          // Footer
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Panadero Time Tracker © ${DateTime.now().year}',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TextField
  Widget _buildTextField() {
    return IDTextField(
      controller: _idnumberController,
      hintText: 'INPUT ID NUMBER HERE',
      obscureText: false,
      onChanged: (value) {
        // Call _fetchAttendanceData when the user types in the ID field
        if (value.isNotEmpty) {
          _fetchAttendanceData(value);
          _fetchRecentLogs(); // Fetch recent logs when ID is entered
        } else {
          setState(() {
            hasTimeIn = null;
            hasLunchOut = null;
          });
        }
      },
    );
  }
}
