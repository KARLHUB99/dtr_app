import 'dart:convert';
import 'package:dtr_app/model/attendance_offline_model.dart';
import 'package:dtr_app/services/attendance_offline_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OfflineAttendanceManualPage extends StatefulWidget {
  const OfflineAttendanceManualPage({super.key});

  @override
  State<OfflineAttendanceManualPage> createState() =>
      _OfflineAttendanceManualPageState();
}

class _OfflineAttendanceManualPageState
    extends State<OfflineAttendanceManualPage> {
  final TextEditingController _idController = TextEditingController();
  List<OfflineAttendance> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadOfflineEntries();
  }

  Future<void> _loadOfflineEntries() async {
    final entries = await OfflineStorageService.getPendingEntries();
    setState(() {
      _entries = entries;
    });
  }

  Future<void> _handleOfflineAction(String label) async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showSnackBar("❌ Please enter an ID number", Colors.red);
      return;
    }

    final now = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    final dummyBase64Image = base64Encode(utf8.encode("placeholder-image"));

    final entry = OfflineAttendance(
      label: label,
      idNumber: id,
      apiUrl: "offline_manual",
      currentTime: now,
      photoBase64: dummyBase64Image,
    );

    await OfflineStorageService.saveOffline(entry);
    _idController.clear();
    _showSnackBar("📴 $label saved offline for $id", Colors.orange);
    await _loadOfflineEntries(); // ✅ Refresh list
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OFFLINE MANUAL ATTENDANCE")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Field
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(fontSize: 26, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: "Enter ID Number",
                hintStyle: GoogleFonts.rajdhani(fontSize: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            _buildActionButton("Time In", () => _handleOfflineAction("Time In"), Colors.green),
            _buildActionButton("Lunch Out", () => _handleOfflineAction("Lunch Out"), Colors.orange),
            _buildActionButton("Lunch In", () => _handleOfflineAction("Lunch In"), Colors.blue),
            _buildActionButton("Time Out", () => _handleOfflineAction("Time Out"), Colors.red),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              "📋 Offline Entries",
              style: GoogleFonts.rajdhani(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(child: Text("No offline records found."))
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text('${entry.label} - ${entry.idNumber}'),
                          subtitle: Text(entry.currentTime),
                          trailing: const Icon(Icons.cloud_off, color: Colors.grey),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(1, 3),
                blurRadius: 5,
              ),
            ],
            borderRadius: BorderRadius.circular(14),
          ),
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
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              elevation: 0,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
