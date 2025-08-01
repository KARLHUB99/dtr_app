import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:dtr_app/components/empid_textfield.dart';
import 'package:dtr_app/components/offline_actionbuttons.dart';
import 'package:dtr_app/model/attendance_offline_model.dart';
import 'package:dtr_app/services/attendance_offline_services.dart';
import 'package:dtr_app/pages/home_page.dart';

class OfflineRecordsPage extends StatefulWidget {
  const OfflineRecordsPage({super.key});

  @override
  State<OfflineRecordsPage> createState() => _OfflineRecordsPageState();
}

class _OfflineRecordsPageState extends State<OfflineRecordsPage> {
  final TextEditingController _idController = TextEditingController();
  List<OfflineAttendance> _offlineLogs = [];
  bool _isLoading = true;
  late Timer _pingTimer;

  @override
  void initState() {
    super.initState();
    _loadOfflineLogs();
    _pingAndSync(); // Initial ping

    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pingAndSync();
    });
  }

  @override
  void dispose() {
    _pingTimer.cancel();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _pingAndSync() async {
    final online = await _pingServer();
    if (online) {
      debugPrint("✅ Ping success, syncing...");
      await OfflineStorageService.syncPendingEntries();
      await _loadOfflineLogs();

      final remaining = await OfflineStorageService.getPendingEntries();
      if (mounted && remaining.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ All offline records synced!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      debugPrint("❌ Still offline, not syncing.");
    }
  }

  Future<bool> _pingServer() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'http://panaderooffice.ddns.net:8080/DTRApi/api/ping.php',
            ),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadOfflineLogs() async {
    final logs = await OfflineStorageService.getPendingEntries();
    if (mounted) {
      setState(() {
        _offlineLogs = logs;
        _isLoading = false;
      });
    }
  }

  String getCurrentTime() => DateFormat('hh:mm a').format(DateTime.now());

  Future<void> _handleOfflineAction(
    String label,
    Function(String) onSuccess,
    String apiUrl,
  ) async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Please enter your ID number."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final timeNow = getCurrentTime();
    final entry = OfflineAttendance(
      label: label,
      idNumber: id,
      apiUrl: apiUrl,
      currentTime: timeNow,
      photoBase64: "",
    );

    await OfflineStorageService.saveOffline(entry);
    onSuccess(timeNow);
    await _loadOfflineLogs();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ $label saved locally at $timeNow"),
        backgroundColor: Colors.orange,
      ),
    );

    _pingAndSync();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _idController.text.trim();
    final logsForUser =
        _offlineLogs.where((e) => e.idNumber == userId).toList();

    final hasTimeIn = logsForUser.any((e) => e.label == "TIME IN");
    final hasLunchOut = logsForUser.any((e) => e.label == "LUNCH OUT");
    final hasLunchIn = logsForUser.any((e) => e.label == "LUNCH IN");
    final hasTimeOut = logsForUser.any((e) => e.label == "TIME OUT");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline Attendance Mode"),
        backgroundColor: const Color(0xFFDA1A29),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Manual Sync",
            onPressed: () async {
              final online = await _pingServer();
              if (!online) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ No internet connection."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔁 Syncing now..."),
                  backgroundColor: Colors.orange,
                ),
              );

              await OfflineStorageService.syncPendingEntries();
              await _loadOfflineLogs();
              final remaining = await OfflineStorageService.getPendingEntries();

              if (mounted && remaining.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ All records synced!"),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "⚠️ Still ${remaining.length} unsynced record(s).",
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    IDTextField(
                      controller: _idController,
                      hintText: 'Enter ID Number',
                      obscureText: false,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    if (userId.isNotEmpty)
                      OfflineActionButtons(
                        handleAction: _handleOfflineAction,
                        hasTimeIn: hasTimeIn,
                        hasLunchOut: hasLunchOut,
                        hasLunchIn: hasLunchIn,
                        hasTimeOut: hasTimeOut,
                      ),
                    const SizedBox(height: 20),
                    Expanded(
                      child:
                          _offlineLogs.isEmpty
                              ? const Center(
                                child: Text("No offline records found."),
                              )
                              : ListView.builder(
                                itemCount: _offlineLogs.length,
                                itemBuilder: (context, index) {
                                  final log = _offlineLogs[index];
                                  return ListTile(
                                    leading: const Icon(Icons.offline_pin),
                                    title: Text(
                                      "${log.idNumber} - ${log.label}",
                                    ),
                                    subtitle: Text(log.currentTime),
                                    trailing: const Icon(Icons.storage),
                                  );
                                },
                              ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
      ),
    );
  }
}
