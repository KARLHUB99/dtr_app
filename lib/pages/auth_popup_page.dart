import 'package:dtr_app/services/auth_service.dart';
import 'package:dtr_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPopupPage extends StatefulWidget {
  final void Function(String username, String fullName) onAuthenticated;

  const AuthPopupPage({super.key, required this.onAuthenticated});

  @override
  State<AuthPopupPage> createState() => _AuthPopupPageState();
}

class _AuthPopupPageState extends State<AuthPopupPage> {
  final TextEditingController _pinController = TextEditingController();
  List<Map<String, String>> users = [];
  Map<String, String>? selectedUser;
  List<String> dept = [];
  String? selectedDepartment;

  @override
  void initState() {
    super.initState();
    _fetchDepartment();
  }

  Future<void> _fetchUsers() async {
    final userService = UserService();
    try {
      final fetchedUsers = await userService.fetchUsers(
        department: selectedDepartment,
      );
      setState(() => users = fetchedUsers);
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  Future<void> _fetchDepartment() async {
    final userService = UserService();
    try {
      final fetchedDept = await userService.fetchDepartments();
      setState(() => dept = fetchedDept);
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          message,
          style: GoogleFonts.rajdhani(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _verifyCredentials() async {
    if (selectedUser == null || _pinController.text.trim().isEmpty) {
      _showSnackBar('Please select a user and enter a PIN.');
      return;
    }

    final authService = AuthService();
    try {
      final result = await authService.verifyCredentials(
        username: selectedUser!['UserName']!,
        password: _pinController.text.trim(),
      );

      if (result['status'] == 'success') {
        widget.onAuthenticated(
          selectedUser!['UserName']!,
          selectedUser!['FullName']!, // ✅ pass full name
        );
        if (context.mounted) Navigator.of(context).pop();
      } else {
        _showSnackBar(result['error'] ?? 'Authentication failed.');
      }
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF8F2),
      title: Text(
        'Authentication',
        style: GoogleFonts.rajdhani(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: const Color(0xFFB3202D),
        ),
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              dept.isNotEmpty
                  ? DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Select Cost Center'),
                    value: selectedDepartment,
                    items:
                        dept
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  d,
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDepartment = value;
                        selectedUser = null;
                        users = [];
                      });
                      _fetchUsers();
                    },
                  )
                  : const CircularProgressIndicator(),

              const SizedBox(height: 10),

              users.isNotEmpty
                  ? DropdownButtonFormField<Map<String, String>>(
                    decoration: _inputDecoration('Select User'),
                    value: selectedUser,
                    items:
                        users
                            .map(
                              (user) => DropdownMenuItem(
                                value: user,
                                child: Text(
                                  user['FullName']!,
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => selectedUser = value),
                  )
                  : const CircularProgressIndicator(),

              const SizedBox(height: 10),

              TextField(
                controller: _pinController,
                obscureText: true,
                decoration: _inputDecoration('Enter PIN'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        _actionButton('Back', Colors.white, Colors.black87, () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }, border: true),
        _actionButton(
          'Confirm',
          const Color(0xFFB3202D),
          Colors.white,
          _verifyCredentials,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.rajdhani(color: Colors.black87, fontSize: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  TextButton _actionButton(
    String text,
    Color bgColor,
    Color fgColor,
    VoidCallback onPressed, {
    bool border = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side:
              border
                  ? const BorderSide(color: Colors.black54)
                  : BorderSide.none,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
