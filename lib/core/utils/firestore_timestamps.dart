import 'package:cloud_firestore/cloud_firestore.dart';

// Helpers for reading and writing timestamps so the same models work against
// Firestore Timestamps and the in-memory mock data (which stores ISO strings).

// Turns a Firestore Timestamp or an ISO string into a DateTime.
DateTime? parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
