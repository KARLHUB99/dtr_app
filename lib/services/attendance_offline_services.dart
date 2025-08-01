import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../model/attendance_offline_model.dart';

class OfflineStorageService {
  /// 📁 Returns the full path to the local JSON storage file
  static Future<String> _getFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/offline_attendance.json';
  }

  /// 💾 Save one attendance record locally (append to file)
  static Future<void> saveOffline(OfflineAttendance entry) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      List<OfflineAttendance> entries = [];

      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content);
          entries = jsonList.map((e) => OfflineAttendance.fromJson(e)).toList();
        }
      }

      entries.add(entry);

      final updatedJson = jsonEncode(entries.map((e) => e.toJson()).toList());
      await file.writeAsString(updatedJson);

      print("💾 Saved offline entry: ${entry.label} for ${entry.idNumber} at ${entry.currentTime}");
    } catch (e) {
      print("❌ Error saving offline entry: $e");
    }
  }

  /// 🔁 Attempts to sync all offline entries to their original API URLs
  static Future<void> syncPendingEntries() async {
    try {
      final entries = await getPendingEntries();
      if (entries.isEmpty) {
        print("📭 No offline entries to sync.");
        return;
      }

      print("🔄 Attempting to sync ${entries.length} offline entries...");

      List<OfflineAttendance> successfullySynced = [];

      for (final entry in entries) {
        try {
          final response = await http.post(
            Uri.parse(entry.apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idnumber': entry.idNumber,
              'time': entry.currentTime,
              'label': entry.label,
              'photo_base64': entry.photoBase64,
            }),
          );

          print("➡️ Sent ${entry.label} for ${entry.idNumber} to ${entry.apiUrl}");
          print("⬅️ Response status: ${response.statusCode}");

          if (response.statusCode == 200) {
            final resBody = jsonDecode(response.body);
            if (resBody['success'] == true) {
              print("✅ Sync success: ${entry.label} for ${entry.idNumber}");
              successfullySynced.add(entry);
            } else {
              print("⚠️ Server rejected entry for ${entry.idNumber}: ${resBody['message'] ?? 'No message'}");
            }
          } else {
            print("❌ Server error ${response.statusCode} for ${entry.idNumber}");
          }
        } catch (e) {
          print("❌ Exception while syncing entry: $e");
        }
      }

      if (successfullySynced.isNotEmpty) {
        await removeEntries(successfullySynced);
        print("🧹 Removed ${successfullySynced.length} synced entries from local file.");

        final remaining = await getPendingEntries();
        if (remaining.isEmpty) {
          final filePath = await _getFilePath();
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
            print("✅ All entries synced. Offline file deleted.");
          }
        }
      } else {
        print("⚠️ No entries were synced.");
      }
    } catch (e) {
      print("❌ Error during syncPendingEntries: $e");
    }
  }

  /// 📦 Loads all offline attendance entries from file
  static Future<List<OfflineAttendance>> getPendingEntries() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList
          .map((e) => OfflineAttendance.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("❌ Error reading offline entries: $e");
      return [];
    }
  }

  /// 🗑️ Remove specific entries from offline file (by exact match)
  static Future<void> removeEntries(List<OfflineAttendance> entriesToRemove) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      if (content.trim().isEmpty) return;

      final List<dynamic> jsonList = jsonDecode(content);
      List<OfflineAttendance> currentEntries = jsonList
          .map((e) => OfflineAttendance.fromJson(e as Map<String, dynamic>))
          .toList();

      currentEntries.removeWhere((entry) => entriesToRemove.any((e) =>
          e.idNumber == entry.idNumber &&
          e.currentTime == entry.currentTime &&
          e.label == entry.label &&
          e.apiUrl == entry.apiUrl));

      final updatedJson = jsonEncode(currentEntries.map((e) => e.toJson()).toList());
      await file.writeAsString(updatedJson);
    } catch (e) {
      print("❌ Error removing offline entries: $e");
    }
  }

  /// ❌ Clears all offline entries from storage
  static Future<void> clearAll() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print("🗑️ All offline entries deleted.");
      }
    } catch (e) {
      print("❌ Error clearing offline entries: $e");
    }
  }
}
