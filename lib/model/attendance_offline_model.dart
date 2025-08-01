class OfflineAttendance {
  final String label;
  final String idNumber;
  final String apiUrl;
  final String currentTime;
  final String photoBase64;

  OfflineAttendance({
    required this.label,
    required this.idNumber,
    required this.apiUrl,
    required this.currentTime,
    required this.photoBase64,
  });

  // ✅ Add this empty factory constructor
  factory OfflineAttendance.empty() {
    return OfflineAttendance(
      label: '',
      idNumber: '',
      apiUrl: '',
      currentTime: '',
      photoBase64: '',
    );
  }

  factory OfflineAttendance.fromJson(Map<String, dynamic> json) {
    return OfflineAttendance(
      label: json['label'],
      idNumber: json['idNumber'],
      apiUrl: json['apiUrl'],
      currentTime: json['currentTime'],
      photoBase64: json['photoBase64'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'idNumber': idNumber,
      'apiUrl': apiUrl,
      'currentTime': currentTime,
      'photoBase64': photoBase64,
    };
  }
}
