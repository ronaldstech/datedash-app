import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'image_editor_screen.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;
  final Set<String> _markedAsRead = {};

  // Voice recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  DateTime? _recordStart;

  late final String _chatId;
  bool _chatReady = false;
  bool _showEmojiPicker = false;
  bool _isSending = false;

  // Search
  bool _showSearch = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final id = await _chatService.getOrCreateChat(_myUid, widget.otherUserId);
    await _chatService.markAsRead(id, _myUid);
    if (mounted) {
      setState(() {
        _chatId = id;
        _chatReady = true;
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_chatReady || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();
    _showEmojiPicker = false;

    try {
      await _chatService.sendMessage(
        chatId: _chatId,
        senderId: _myUid,
        receiverId: widget.otherUserId,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _isRecording = true;
      _recordStart = DateTime.now();
      _recordDuration = Duration.zero;
    });

    // Update timer every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording || !mounted) return false;
      setState(() {
        _recordDuration =
            DateTime.now().difference(_recordStart ?? DateTime.now());
      });
      return _isRecording;
    });
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording) return;

    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
    });

    if (path == null || !_chatReady) return;

    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) return;

    setState(() => _isSending = true);

    try {
      final mediaUrl = await _chatService.uploadVoiceFile(
        filePath: path,
        chatId: _chatId,
        userId: _myUid,
      );

      await _chatService.sendMediaMessage(
        chatId: _chatId,
        senderId: _myUid,
        receiverId: widget.otherUserId,
        text: '',
        messageType: MessageType.voice,
        mediaUrl: mediaUrl,
        voiceDuration: file.lengthSync(),
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending voice note: $e')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _cancelRecording() async {
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      if (!mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageEditorScreen(imageFile: File(image.path)),
        ),
      );

      if (result == null) return;

      final File finalFile = result['file'];
      final String caption = result['caption'] ?? '';

      setState(() {
        _isSending = true;
        _showEmojiPicker = false;
      });

      final mediaUrl = await _chatService.uploadFile(
        filePath: finalFile.path,
        fileType: 'images',
        chatId: _chatId,
        userId: _myUid,
      );

      await _chatService.sendMediaMessage(
        chatId: _chatId,
        senderId: _myUid,
        receiverId: widget.otherUserId,
        text: caption,
        messageType: MessageType.image,
        mediaUrl: mediaUrl,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      if (!mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageEditorScreen(imageFile: File(image.path)),
        ),
      );

      if (result == null) return;

      final File finalFile = result['file'];
      final String caption = result['caption'] ?? '';

      setState(() {
        _isSending = true;
        _showEmojiPicker = false;
      });

      final mediaUrl = await _chatService.uploadFile(
        filePath: finalFile.path,
        fileType: 'images',
        chatId: _chatId,
        userId: _myUid,
      );

      await _chatService.sendMediaMessage(
        chatId: _chatId,
        senderId: _myUid,
        receiverId: widget.otherUserId,
        text: caption,
        messageType: MessageType.image,
        mediaUrl: mediaUrl,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Call Handlers ───────────────────────────────────────────────────────

  void _showVoiceCall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CallSheet(
        name: widget.otherUserName,
        photo: widget.otherUserPhoto,
        isVideo: false,
        chatId: _chatId,
        chatService: _chatService,
        senderId: _myUid,
        receiverId: widget.otherUserId,
      ),
    );
  }

  void _showVideoCall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CallSheet(
        name: widget.otherUserName,
        photo: widget.otherUserPhoto,
        isVideo: true,
        chatId: _chatId,
        chatService: _chatService,
        senderId: _myUid,
        receiverId: widget.otherUserId,
      ),
    );
  }

  // ─── Clear Chat ───────────────────────────────────────────────────────────

  void _clearChatConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Chat',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'All messages with ${widget.otherUserName} will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _chatService.clearChat(_chatId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat cleared'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: \$e')),
                  );
                }
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _chatService.getUserOnlineStatus(widget.otherUserId),
      builder: (context, onlineSnapshot) {
        final isRecipientOnline = onlineSnapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left_2),
              onPressed: () => Navigator.pop(context, true),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFF4D85).withOpacity(0.2),
                  backgroundImage: widget.otherUserPhoto != null
                      ? NetworkImage(widget.otherUserPhoto!)
                      : null,
                  child: widget.otherUserPhoto == null
                      ? const Icon(Iconsax.user, size: 18, color: Color(0xFFFF4D85))
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isRecipientOnline ? 'Active now' : 'Offline',
                      style: TextStyle(
                        color: isRecipientOnline ? Colors.green : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.call),
                tooltip: 'Voice Call',
                onPressed: _showVoiceCall,
              ),
              IconButton(
                icon: const Icon(Iconsax.video),
                tooltip: 'Video Call',
                onPressed: _showVideoCall,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'clear':
                      _clearChatConfirm();
                      break;
                    case 'profile':
                      // Navigate to profile — already available via the swipe card
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.otherUserName}\'s profile'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      break;
                    case 'search':
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'search',
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 20),
                        SizedBox(width: 12),
                        Text('Search', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Iconsax.user, size: 20),
                        SizedBox(width: 12),
                        Text('View Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                        const SizedBox(width: 12),
                        Text('Clear Chat',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
              // Search bar
              if (_showSearch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _showSearch = false;
                          _searchQuery = '';
                          _searchController.clear();
                        }),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: !_chatReady
                    ? const Center(child: SizedBox.shrink())
                    : StreamBuilder<List<ChatMessage>>(
                        stream: _chatService.getMessagesStreamSmart(_chatId),
                        builder: (context, snapshot) {
                          final messages = snapshot.data ?? [];
                          final filtered = _searchQuery.isEmpty
                              ? messages
                              : messages
                                  .where((m) => m.text.toLowerCase().contains(_searchQuery))
                                  .toList();

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            for (final msg in messages) {
                              if (!msg.isRead &&
                                  msg.senderId != _myUid &&
                                  !_markedAsRead.contains(msg.id)) {
                                _markedAsRead.add(msg.id);
                                _chatService.markMessageAsRead(_chatId, msg.id);
                              }
                            }
                          });

                          if (filtered.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4D85).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _searchQuery.isNotEmpty ? Icons.search_off : Iconsax.message,
                                      size: 40,
                                      color: const Color(0xFFFF4D85),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No messages found'
                                        : 'Say hi to ${widget.otherUserName}!',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Try a different search term'
                                        : 'Start the conversation',
                                    style: TextStyle(color: Theme.of(context).hintColor),
                                  ),
                                ],
                              ),
                            );
                          }

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients &&
                                _scrollController.position.maxScrollExtent > 0) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              );
                            }
                          });

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final msg = filtered[index];
                              final isMe = msg.senderId == _myUid;
                              final showTime = index == 0 ||
                                  filtered[index]
                                          .timestamp
                                          .difference(
                                              filtered[index - 1].timestamp)
                                          .inMinutes >
                                      10;

                              return Column(
                                children: [
                                  if (showTime)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Text(
                                        _formatTime(msg.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).hintColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  _buildMessageBubble(
                                      msg, isMe, isRecipientOnline),
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),
              if (_isRecording) _buildRecordingBar(),
              if (_showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _messageController.text += emoji.emoji;
                      setState(() {});
                    },
                  ),
                ),
              _buildMessageInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordingBar() {
    final secs = _recordDuration.inSeconds;
    final timeStr =
        '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFFF4D85).withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Color(0xFFFF4D85), size: 10),
          const SizedBox(width: 10),
          Text(
            'Recording  $timeStr',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF4D85),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _cancelRecording,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      ChatMessage msg, bool isMe, bool isRecipientOnline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFFF4D85).withOpacity(0.15),
              backgroundImage: widget.otherUserPhoto != null
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null
                  ? const Icon(Iconsax.user, size: 12, color: Color(0xFFFF4D85))
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: _buildMessageContent(msg, isMe, isRecipientOnline),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _buildTickMarks(msg, isRecipientOnline),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(
      ChatMessage msg, bool isMe, bool isRecipientOnline) {
    if (msg.messageType == MessageType.image && msg.mediaUrl != null) {
      return Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFFF4D85)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                msg.mediaUrl!.replaceFirst('unimarket-mw.com/uploads/',
                    'unimarket-mw.com/datedash/api/uploads/'),
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width * 0.75,
                height: 250,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: 250,
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF4D85),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 32),
                  ),
                ),
              ),
            ),
            if (msg.text.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (msg.messageType == MessageType.voice && msg.mediaUrl != null) {
      return _VoiceNoteBubble(
        url: msg.mediaUrl!,
        isMe: isMe,
      );
    }

    if (msg.messageType == MessageType.gif && msg.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
        child: Image.network(
          msg.mediaUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.gif_box_outlined, size: 32),
          ),
        ),
      );
    }

    // Default text message
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:
            isMe ? const Color(0xFFFF4D85) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        msg.text,
        style: TextStyle(
          color: isMe
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildTickMarks(ChatMessage msg, bool isRecipientOnline) {
    if (msg.isRead) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done, size: 14, color: Color(0xFFFF4D85)),
          SizedBox(width: 1),
          Icon(Icons.done, size: 14, color: Color(0xFFFF4D85)),
        ],
      );
    } else if (isRecipientOnline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 1),
          Icon(Icons.done, size: 14, color: Colors.grey[400]),
        ],
      );
    } else {
      return Icon(Icons.done, size: 14, color: Colors.grey[400]);
    }
  }

  Widget _buildMessageInput() {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Camera Button
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: IconButton(
              icon: const Icon(Iconsax.camera),
              color: const Color(0xFFFF4D85),
              iconSize: 22,
              visualDensity: VisualDensity.compact,
              splashRadius: 20,
              onPressed: _isSending ? null : _pickCamera,
            ),
          ),
          // Gallery Button
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: IconButton(
              icon: const Icon(Iconsax.image),
              color: const Color(0xFFFF4D85),
              iconSize: 22,
              visualDensity: VisualDensity.compact,
              splashRadius: 20,
              onPressed: _isSending ? null : _pickImage,
            ),
          ),
          // Text input
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: IconButton(
                      icon: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                        color: Theme.of(context).hintColor,
                        size: 22,
                      ),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 20,
                      onPressed: () => setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      }),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (val) => setState(() {}),
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle:
                            TextStyle(color: Theme.of(context).hintColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(
                            top: 12, bottom: 12, right: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Send / Mic button
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 4),
            child: hasText
                // Send text button
                ? GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D85), Color(0xFFFF758C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4D85).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: _isSending
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                            )
                          : const Icon(
                              Iconsax.send_1,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  )
                // Hold-to-record mic button
                : Listener(
                    onPointerDown: (_) => _startRecording(),
                    onPointerUp: (_) => _stopAndSendRecording(),
                    onPointerCancel: (_) => _cancelRecording(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: _isRecording
                            ? const LinearGradient(
                                colors: [Color(0xFFFF4D85), Color(0xFFFF758C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _isRecording
                            ? null
                            : Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        border: _isRecording
                            ? null
                            : Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.15),
                                width: 1.5,
                              ),
                        boxShadow: _isRecording
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF4D85).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none_outlined,
                        color: _isRecording
                            ? Colors.white
                            : Theme.of(context).hintColor,
                        size: 22,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

// ─── Call Bottom Sheet ───────────────────────────────────────────────────────

class _CallSheet extends StatelessWidget {
  final String name;
  final String? photo;
  final bool isVideo;
  final String chatId;
  final ChatService chatService;
  final String senderId;
  final String receiverId;

  const _CallSheet({
    required this.name,
    this.photo,
    required this.isVideo,
    required this.chatId,
    required this.chatService,
    required this.senderId,
    required this.receiverId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 52,
              backgroundColor: const Color(0xFFFF4D85).withOpacity(0.15),
              backgroundImage: photo != null ? NetworkImage(photo!) : null,
              child: photo == null
                  ? const Icon(Icons.person, size: 48, color: Color(0xFFFF4D85))
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              isVideo ? 'Starting video call...' : 'Starting voice call...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 36),
            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline
                _CallButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  label: 'End',
                  onTap: () => Navigator.pop(context),
                ),
                // Accept
                _CallButton(
                  icon: isVideo ? Icons.videocam : Icons.call,
                  color: const Color(0xFFFF4D85),
                  label: isVideo ? 'Video' : 'Call',
                  onTap: () async {
                    Navigator.pop(context);

                    // Build a Jitsi Meet room unique to this chat
                    // Voice-only: video starts muted; Video: both enabled
                    final roomName = 'datedash-${chatId.replaceAll('_', '-')}';
                    final fragment = isVideo
                        ? 'config.startWithVideoMuted=false&config.startWithAudioMuted=false'
                        : 'config.startWithVideoMuted=true&config.startWithAudioMuted=false';
                    final url = Uri.parse('https://meet.jit.si/$roomName#$fragment');

                    // Send a join-link system message to the chat
                    final callType = isVideo ? '🎥 Video' : '📞 Voice';
                    await chatService.sendMessage(
                      chatId: chatId,
                      senderId: senderId,
                      receiverId: receiverId,
                      text: '$callType call started. Join here: https://meet.jit.si/$roomName',
                    );

                    // Launch Jitsi in browser / Jitsi app
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallButton(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Voice Note Playback Bubble ──────────────────────────────────────────────

class _VoiceNoteBubble extends StatefulWidget {
  final String url;
  final bool isMe;

  const _VoiceNoteBubble({required this.url, required this.isMe});

  @override
  State<_VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<_VoiceNoteBubble> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    final bubbleColor = widget.isMe
        ? const Color(0xFFFF4D85)
        : Theme.of(context).cardColor;
    final contentColor = widget.isMe ? Colors.white : const Color(0xFFFF4D85);
    final textColor = widget.isMe
        ? Colors.white.withOpacity(0.85)
        : Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
          bottomRight: Radius.circular(widget.isMe ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: contentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: contentColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform progress bar
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: contentColor,
                    inactiveTrackColor: contentColor.withOpacity(0.25),
                    thumbColor: contentColor,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (val) {
                      final seekTo = Duration(
                          milliseconds:
                              (_duration.inMilliseconds * val).round());
                      _player.seek(seekTo);
                    },
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(fontSize: 10, color: textColor),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(fontSize: 10, color: textColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
