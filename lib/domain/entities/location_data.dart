class LocationData {
  final String country;
  final String city;
  final String? neighborhood;
  final double latitude;
  final double longitude;

  LocationData({
    required this.country,
    required this.city,
    this.neighborhood,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'city': city,
      'neighborhood': neighborhood,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      country: json['country'],
      city: json['city'],
      neighborhood: json['neighborhood'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
