import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import 'notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _bookingsCollection => _firestore.collection('bookings');

  /// Creates a new booking request
  Future<void> createBooking(BookingModel booking, {String? senderName}) async {
    try {
      final docRef = await _bookingsCollection.add(booking.toMap());
      
      // Notify the receiver
      await NotificationService().sendNotification(
        recipientId: booking.receiverId,
        senderId: booking.senderId,
        senderName: senderName ?? 'Someone',
        type: 'booking_request',
      );
      
      debugPrint('BookingService: Created booking ${docRef.id}');
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }

  /// Updates booking status (accepted, rejected, cancelled)
  Future<void> updateBookingStatus(String bookingId, BookingStatus status, {required String currentUserId, required String otherUserId, String? senderName}) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': status.toString().split('.').last,
      });

      // Notify the other user about the status change
      await NotificationService().sendNotification(
        recipientId: otherUserId,
        senderId: currentUserId,
        senderName: senderName ?? 'Someone',
        type: 'booking_${status.toString().split('.').last}',
      );

      debugPrint('BookingService: Updated booking $bookingId to $status');
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      rethrow;
    }
  }

  /// Returns a stream of bookings for a specific user (either as sender or receiver)
  Stream<List<BookingModel>> getUserBookingsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where(Filter.or(
          Filter('senderId', isEqualTo: userId),
          Filter('receiverId', isEqualTo: userId),
        ))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList();
    });
  }

  /// Returns a stream of pending received bookings for a user
  Stream<List<BookingModel>> getPendingReceivedBookingsStream(String userId) {
    return _bookingsCollection
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList();
    });
  }

  /// Checks if there's a pending booking between two users
  Future<BookingModel?> getPendingBooking(String uid1, String uid2) async {
    try {
      final snapshot = await _bookingsCollection
          .where('status', isEqualTo: 'pending')
          .get();

      // Firestore doesn't support complex OR queries with multiple fields across different docs easily in a single where
      // So we filter manually or use two queries. For simplicity in a small app, we can filter.
      final doc = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'];
        final receiverId = data['receiverId'];
        return (senderId == uid1 && receiverId == uid2) || (senderId == uid2 && receiverId == uid1);
      }).firstOrNull;

      if (doc != null) {
        return BookingModel.fromDoc(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error checking pending booking: $e');
      return null;
    }
  }
}
