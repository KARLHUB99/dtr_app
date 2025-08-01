class GeofenceModel {
  final double latitude;
  final double longitude;
  final double radius;

  GeofenceModel({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      latitude: double.parse(json['Latitude'].toString()),
      longitude: double.parse(
        json['Longtitude'].toString(),
      ), // Note: typo in API key
      radius: double.parse(json['Meter'].toString()),
    );
  }
}
