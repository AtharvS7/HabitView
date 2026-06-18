import 'package:cloud_firestore/cloud_firestore.dart';

class TimestampMapper {
  static DateTime? fromFirestore(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static dynamic toFirestore(DateTime? date) {
    return date == null ? null : Timestamp.fromDate(date);
  }
}
