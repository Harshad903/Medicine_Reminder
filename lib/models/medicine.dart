class Medicine {
  final List<dynamic>? notificationIDs;
  final String? medicineName;
  final String? dosage;
  final String? medicineType;
  final int? interval;
  final String? startTime;

  Medicine(
      {this.notificationIDs,
        this.medicineName,
        this.dosage,
        this.medicineType,
        this.startTime,
        this.interval});

  //geters
  String get getName => medicineName!;
  String get getDosage => dosage!;
  String get getType => medicineType!;
  int get getInterval => interval!;
  String get getStartTime => startTime!;
  List<dynamic> get getIDs => notificationIDs!;

  Map<String, dynamic> toJson() {
    return {
      'ids': notificationIDs,
      'name': medicineName,
      'dosage': dosage,
      'type': medicineType,
      'interval': interval,
      'start': startTime,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> parsedJson) {
    return Medicine(
      notificationIDs: parsedJson['ids'],
      medicineName: parsedJson['name'],
      dosage: parsedJson['dosage'].toString(),
      medicineType: parsedJson['type'],
      interval: parsedJson['interval'],
      startTime: parsedJson['start'],
    );
  }
}
