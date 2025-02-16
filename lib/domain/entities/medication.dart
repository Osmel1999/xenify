class Medication {
  final String name;
  final int intervalHours;
  final bool isIndefinite;
  final DateTime? endDate;
  final DateTime nextDose;

  Medication({
    required this.name,
    required this.intervalHours,
    required this.isIndefinite,
    this.endDate,
    required this.nextDose,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'intervalHours': intervalHours,
      'isIndefinite': isIndefinite,
      'endDate': endDate?.toIso8601String(),
      'nextDose': nextDose.toIso8601String(), // Convertir DateTime a String
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'] as String,
      intervalHours: json['intervalHours'] as int,
      isIndefinite: json['isIndefinite'] as bool,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      nextDose: DateTime.parse(json['nextDose']),
    );
  }
}
