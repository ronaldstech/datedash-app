import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, accepted, rejected, cancelled }

class BookingModel {
  final String id;
  final String senderId;
  final String receiverId;
  final DateTime dateTime;
  final String? location;
  final BookingStatus status;
  final DateTime timestamp;
  final String? note;

  BookingModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.dateTime,
    this.location,
    this.status = BookingStatus.pending,
    required this.timestamp,
    this.note,
  });

  factory BookingModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'],
      status: _parseStatus(data['status'] ?? 'pending'),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'],
    );
  }

  static BookingStatus _parseStatus(String status) {
    switch (status) {
      case 'accepted':
        return BookingStatus.accepted;
      case 'rejected':
        return BookingStatus.rejected;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'receiverId': receiverId,
        'dateTime': Timestamp.fromDate(dateTime),
        'location': location,
        'status': status.toString().split('.').last,
        'timestamp': FieldValue.serverTimestamp(),
        'note': note,
      };
}
