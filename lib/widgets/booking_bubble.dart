import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../utils/date_formatter.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingBubble extends StatefulWidget {
  final String bookingId;
  final bool isMe;
  final String otherUserId;
  final String otherUserName;

  const BookingBubble({
    super.key,
    required this.bookingId,
    required this.isMe,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<BookingBubble> createState() => _BookingBubbleState();
}

class _BookingBubbleState extends State<BookingBubble> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final booking = BookingModel.fromDoc(snapshot.data!);
        final isPending = booking.status == BookingStatus.pending;
        final isAccepted = booking.status == BookingStatus.accepted;
        final isRejected = booking.status == BookingStatus.rejected;
        final isCancelled = booking.status == BookingStatus.cancelled;

        return Container(
          width: 260,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAccepted
                  ? Colors.green.withValues(alpha: 0.3)
                  : isRejected
                      ? Colors.red.withValues(alpha: 0.3)
                      : const Color(0xFFFF4D85).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? Colors.green.withValues(alpha: 0.1)
                      : isRejected
                          ? Colors.red.withValues(alpha: 0.1)
                          : const Color(0xFFFF4D85).withValues(alpha: 0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAccepted
                          ? Icons.check_circle
                          : isRejected
                              ? Icons.cancel
                              : Iconsax.calendar_add,
                      size: 20,
                      color: isAccepted
                          ? Colors.green
                          : isRejected
                              ? Colors.red
                              : const Color(0xFFFF4D85),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAccepted
                          ? 'Date Confirmed!'
                          : isRejected
                              ? 'Date Declined'
                              : isCancelled
                                  ? 'Date Cancelled'
                                  : 'Date Proposal',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isAccepted
                            ? Colors.green
                            : isRejected
                                ? Colors.red
                                : const Color(0xFFFF4D85),
                      ),
                    ),
                  ],
                ),
              ),

              // Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      context,
                      Iconsax.calendar,
                      DateFormatter.formatBookingDateTime(booking.dateTime),
                    ),
                    if (booking.location != null) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                          context, Iconsax.location, booking.location!),
                    ],
                    if (booking.note != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '"${booking.note}"',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).hintColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              if (isPending && !widget.isMe)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              _updateStatus(BookingStatus.rejected),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side:
                                  const BorderSide(color: Colors.red, width: 1),
                            ),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateStatus(BookingStatus.accepted),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ),

              if (isPending && widget.isMe)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Center(
                    child: Text(
                      'Waiting for ${widget.otherUserName}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              if (isAccepted)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Icon(Icons.celebration, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'It\'s a date!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _updateStatus(BookingStatus status) async {
    final profileProvider = context.read<ProfileProvider>();
    final myUid = profileProvider.currentUser?.uid;
    if (myUid == null) return;

    try {
      await BookingService().updateBookingStatus(
        widget.bookingId,
        status,
        currentUserId: myUid,
        otherUserId: widget.otherUserId,
        senderName: profileProvider.displayName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }
}

