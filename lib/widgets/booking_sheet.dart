import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import '../utils/date_formatter.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class BookingSheet extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String chatId;
  final String myUid;

  const BookingSheet({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.chatId,
    required this.myUid,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF4D85),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF4D85),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submitBooking() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final booking = BookingModel(
      id: '', // Will be set by Firestore
      senderId: widget.myUid,
      receiverId: widget.otherUserId,
      dateTime: finalDateTime,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      timestamp: DateTime.now(),
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    try {
      final bookingService = BookingService();
      // We need to get the booking ID after creation to send in chat
      // Let's modify createBooking to return the ID or just use a manual ID
      final docRef = FirebaseFirestore.instance.collection('bookings').doc();
      final bookingWithId = BookingModel(
        id: docRef.id,
        senderId: booking.senderId,
        receiverId: booking.receiverId,
        dateTime: booking.dateTime,
        location: booking.location,
        timestamp: booking.timestamp,
        note: booking.note,
      );

      await docRef.set(bookingWithId.toMap());
      
      // Send message in chat
      final dateStr = DateFormatter.formatBookingDateTime(finalDateTime);
      await ChatService().sendBookingMessage(
        chatId: widget.chatId,
        senderId: widget.myUid,
        receiverId: widget.otherUserId,
        bookingId: docRef.id,
        text: 'I\'d like to propose a date on $dateStr',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Date proposal sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error proposing date: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Iconsax.calendar_add, color: Color(0xFFFF4D85), size: 28),
              const SizedBox(width: 12),
              Text(
                'Plan a Date with ${widget.otherUserName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Date Selection
          _buildSelectionRow(
            icon: Iconsax.calendar,
            label: 'Select Date',
            value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            onTap: _selectDate,
          ),
          const SizedBox(height: 16),
          
          // Time Selection
          _buildSelectionRow(
            icon: Iconsax.clock,
            label: 'Select Time',
            value: _selectedTime.format(context),
            onTap: _selectTime,
          ),
          const SizedBox(height: 24),
          
          // Location
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Where? (e.g. Starbucks, Central Park)',
              prefixIcon: const Icon(Iconsax.location),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Note
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add a sweet note...',
              prefixIcon: const Icon(Iconsax.message_edit),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D85),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Send Date Proposal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFF4D85),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
