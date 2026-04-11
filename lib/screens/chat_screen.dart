import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'dart:io';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import '../widgets/profile_detail_sheet.dart';
import '../providers/language_provider.dart';
import 'image_editor_screen.dart';
import '../utils/date_formatter.dart';
import '../providers/profile_provider.dart';

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

  late String _chatId;
  bool _chatReady = false;
  bool _showEmojiPicker = false;
  ChatMessage? _editingMessage;
  bool _isSending = false;

  // Search
  bool _showSearch = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _messageCount = 0; // used to gate voice/video calls
  bool _isMatched = false;
  bool _hasReply = false;
  int _messagesFromMeCount = 0;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final id = await _chatService.getOrCreateChat(_myUid, widget.otherUserId);
    await _chatService.markAsRead(id, _myUid);
    final matched =
        await ProfileService().checkMatchStatus(_myUid, widget.otherUserId);
    if (mounted) {
      setState(() {
        _chatId = id;
        _isMatched = matched;
        _chatReady = true;
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_chatReady || _isSending) return;

    final languageProvider = context.read<LanguageProvider>();
    setState(() => _isSending = true);
    // Clear state early
    final msgToEdit = _editingMessage;
    _messageController.clear();
    _showEmojiPicker = false;
    setState(() => _editingMessage = null);

    try {
      if (msgToEdit != null) {
        await _chatService.editMessage(_chatId, msgToEdit.id, text);
      } else {
        await _chatService.sendMessage(
          chatId: _chatId,
          senderId: _myUid,
          receiverId: widget.otherUserId,
          text: text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${languageProvider.getString('chat_error_sending')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<bool> _checkAndConsumeCredits() async {
    final profileProvider = context.read<ProfileProvider>();
    final lp = context.read<LanguageProvider>();
    final user = profileProvider.userProfile;

    if (user == null) return false;

    // Premium users have unlimited messages
    if (user.isPremium) return true;

    // Check balance
    if (user.credits >= 10) {
      try {
        await profileProvider.useCredits(10);
        return true;
      } catch (e) {
        debugPrint('Error deducting credits: $e');
        return false;
      }
    } else {
      _showInsufficientCreditsDialog(lp);
      return false;
    }
  }

  void _showInsufficientCreditsDialog(LanguageProvider lp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Iconsax.wallet_3, color: Color(0xFFFF4D85)),
            const SizedBox(width: 12),
            Text(lp.getString('insufficient_credits_title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lp.getString('insufficient_credits_msg')),
            const SizedBox(height: 12),
            Text(
              lp.getString('premium_benefit_msg'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lp.getString('cancel'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileProvider>().navigateToPremium(1);
              Navigator.pop(context); // Close chat screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D85),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(lp.getString('get_credits')),
          ),
        ],
      ),
    );
  }

  void _handleSendOrRecord() async {
    if (_isRecording) {
      _stopAndSendRecording();
    } else if (_messageController.text.trim().isNotEmpty ||
        _editingMessage != null) {
      // For editing, we don't charge credits (conventionally)
      if (_editingMessage != null) {
        _sendMessage();
        return;
      }

      // Check and use credits for new text messages
      if (await _checkAndConsumeCredits()) {
        _sendMessage();
      }
    } else {
      // Check credits before allowing voice recording
      if (await _checkAndConsumeCredits()) {
        _startRecording();
      }
    }
  }

  Future<void> _startRecording() async {
    final languageProvider = context.read<LanguageProvider>();
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  languageProvider.getString('microphone_permission_denied'))),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    setState(() {
      _isRecording = true;
      _recordStart = DateTime.now();
      _recordDuration = Duration.zero;
    });

    try {
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path);
    } catch (e) {
      debugPrint('Error starting recorder: $e');
      if (mounted) setState(() => _isRecording = false);
      return;
    }

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

    final languageProvider = context.read<LanguageProvider>();
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
          SnackBar(
              content: Text(
                  '${languageProvider.getString('error_sending_voice')}: $e')),
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
    final languageProvider = context.read<LanguageProvider>();
    if (await _checkAndConsumeCredits()) {
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
            SnackBar(
                content: Text(
                    '${languageProvider.getString('error_uploading_image')}: $e')),
          );
        }
      } finally {
        setState(() => _isSending = false);
      }
    } // closes: if (await _checkAndConsumeCredits())
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

  // ─── Call Handlers

  void _showCallLockedSnack() {
    final remaining = 6 - _messageCount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Send ${remaining > 1 ? '$remaining more messages' : '1 more message'} to unlock voice & video calls!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF4D85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
    final languageProvider = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          languageProvider.getString('clear_chat_title'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          languageProvider
              .getString('clear_chat_confirm_message')
              .replaceAll('{name}', widget.otherUserName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(languageProvider.getString('cancel')),
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
                    SnackBar(
                      content: Text(
                          languageProvider.getString('chat_cleared_snack')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(languageProvider.getString('reset')),
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
    final languageProvider = context.watch<LanguageProvider>();
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
                  radius: 16,
                  backgroundColor: const Color(0xFFFF4D85).withOpacity(0.2),
                  backgroundImage: widget.otherUserPhoto != null
                      ? NetworkImage(widget.otherUserPhoto!)
                      : null,
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint(
                        'Error loading app bar profile image: $exception');
                  },
                  child: widget.otherUserPhoto == null
                      ? const Icon(Iconsax.user,
                          size: 16, color: Color(0xFFFF4D85))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.otherUserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        isRecipientOnline
                            ? languageProvider.getString('active_now')
                            : languageProvider.getString('offline'),
                        style: TextStyle(
                          color: isRecipientOnline ? Colors.green : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Iconsax.call,
                  color: _messageCount >= 6
                      ? null
                      : Theme.of(context).disabledColor,
                ),
                tooltip: _messageCount >= 6
                    ? languageProvider.getString('voice_call_tooltip')
                    : 'Exchange at least 6 messages to unlock calls',
                onPressed:
                    _messageCount >= 6 ? _showVoiceCall : _showCallLockedSnack,
                iconSize: 17,
              ),
              IconButton(
                icon: Icon(
                  Iconsax.video,
                  color: _messageCount >= 6
                      ? null
                      : Theme.of(context).disabledColor,
                ),
                tooltip: _messageCount >= 6
                    ? languageProvider.getString('video_call_tooltip')
                    : 'Exchange at least 6 messages to unlock calls',
                onPressed:
                    _messageCount >= 6 ? _showVideoCall : _showCallLockedSnack,
                iconSize: 17,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'clear':
                      _clearChatConfirm();
                      break;
                    case 'profile':
                      final profile = await ProfileService()
                          .getUserProfile(widget.otherUserId);
                      if (profile != null && mounted) {
                        showModalBottomSheet(
                          // ignore: use_build_context_synchronously
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ProfileDetailSheet(
                            profile: profile,
                            onLike: () {},
                            onDislike: () {},
                            onMessage: () => Navigator.pop(context),
                          ),
                        );
                      }
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
                  PopupMenuItem(
                    value: 'search',
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20),
                        const SizedBox(width: 12),
                        Text(languageProvider.getString('nav_explore'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Iconsax.user, size: 20),
                        const SizedBox(width: 12),
                        Text(languageProvider.getString('view_profile'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 20, color: Colors.red.shade400),
                        const SizedBox(width: 12),
                        Text(languageProvider.getString('clear_chat_title'),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText:
                          languageProvider.getString('search_messages_hint'),
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
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              // --- Restriction Banner ---
              if (!_isMatched && !_hasReply && _messagesFromMeCount >= 1)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.amber.withOpacity(0.12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          languageProvider
                              .getString('chat_waiting_for_reply')
                              .replaceAll('{name}', widget.otherUserName),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: !_chatReady
                    ? const Center(child: SizedBox.shrink())
                    : StreamBuilder<List<ChatMessage>>(
                        stream: _chatService.getMessagesStreamSmart(_chatId),
                        builder: (context, snapshot) {
                          final messages = snapshot.data ?? [];

                          // Update state for call-gating and message restriction
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              bool needsUpdate = false;
                              if (_messageCount != messages.length) {
                                _messageCount = messages.length;
                                needsUpdate = true;
                              }

                              final myMsgs = messages
                                  .where((m) => m.senderId == _myUid)
                                  .length;
                              if (_messagesFromMeCount != myMsgs) {
                                _messagesFromMeCount = myMsgs;
                                needsUpdate = true;
                              }

                              final hasRep = messages
                                  .any((m) => m.senderId == widget.otherUserId);
                              if (_hasReply != hasRep) {
                                _hasReply = hasRep;
                                needsUpdate = true;
                              }

                              if (needsUpdate) setState(() {});
                            }
                          });

                          final filtered = _searchQuery.isEmpty
                              ? messages
                              : messages
                                  .where((m) => m.text
                                      .toLowerCase()
                                      .contains(_searchQuery))
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
                                      color: const Color(0xFFFF4D85)
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _searchQuery.isNotEmpty
                                          ? Icons.search_off
                                          : Iconsax.message,
                                      size: 40,
                                      color: const Color(0xFFFF4D85),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? languageProvider
                                            .getString('no_messages_found')
                                        : languageProvider
                                            .getString('say_hi_to')
                                            .replaceAll(
                                                '{name}', widget.otherUserName),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? languageProvider
                                            .getString('try_different_search')
                                        : languageProvider
                                            .getString('start_conversation'),
                                    style: TextStyle(
                                        color: Theme.of(context).hintColor),
                                  ),
                                ],
                              ),
                            );
                          }

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients &&
                                _scrollController.position.maxScrollExtent >
                                    0) {
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
                              final prevMsg =
                                  index > 0 ? filtered[index - 1] : null;
                              final showDateDivider = prevMsg == null ||
                                  msg.timestamp.day != prevMsg.timestamp.day ||
                                  msg.timestamp.month !=
                                      prevMsg.timestamp.month ||
                                  msg.timestamp.year != prevMsg.timestamp.year;

                              return Column(
                                children: [
                                  if (showDateDivider)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .dividerColor
                                                .withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            DateFormatter.formatDateDivider(
                                                msg.timestamp,
                                                languageProvider),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Theme.of(context).hintColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  _buildMessageBubble(msg, isMe,
                                      isRecipientOnline, languageProvider),
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),
              if (_isRecording) _buildRecordingBar(languageProvider),
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
              _buildMessageInput(languageProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordingBar(LanguageProvider languageProvider) {
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
            '${languageProvider.getString('recording_label')}  $timeStr',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF4D85),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _cancelRecording,
            child: Text(
              languageProvider.getString('cancel_recording'),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(LanguageProvider languageProvider) {
    final isRestricted = !_isMatched && !_hasReply && _messagesFromMeCount >= 1;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Iconsax.add_circle, color: Color(0xFFFF4D85)),
                onPressed: isRestricted ? null : _pickImage,
                color: isRestricted ? Colors.grey : const Color(0xFFFF4D85),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.emoji_emotions_outlined,
                            color: isRestricted
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.shade400,
                            size: 22),
                        onPressed: isRestricted
                            ? null
                            : () => setState(
                                () => _showEmojiPicker = !_showEmojiPicker),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !isRestricted,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: isRestricted
                                ? (languageProvider
                                    .getString('chat_waiting_for_reply_hint'))
                                : _editingMessage != null
                                    ? languageProvider.getString('edit_message')
                                    : languageProvider.getString('message'),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (v) => setState(() {}),
                          onSubmitted: (_) => _handleSendOrRecord(),
                        ),
                      ),
                      if (_editingMessage != null)
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.grey, size: 20),
                          onPressed: () {
                            setState(() {
                              _editingMessage = null;
                              _messageController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isRestricted)
                GestureDetector(
                  onTap: _handleSendOrRecord,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4D85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      (_isRecording ||
                              (_messageController.text.trim().isNotEmpty &&
                                  _editingMessage == null))
                          ? Iconsax.send_1
                          : _editingMessage != null
                              ? Icons.check
                              : Iconsax.microphone_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              if (isRestricted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Iconsax.lock, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionMenu(ChatMessage msg, LanguageProvider lp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (msg.messageType == MessageType.text)
                ListTile(
                  leading:
                      const Icon(Icons.edit_outlined, color: Color(0xFFFF4D85)),
                  title: Text(lp.getString('edit')),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _editingMessage = msg;
                      _messageController.text = msg.text;
                    });
                  },
                ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(lp.getString('delete'),
                    style: const TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(msg, lp);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ChatMessage msg, LanguageProvider lp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lp.getString('delete_message_title')),
        content: Text(lp.getString('delete_message_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lp.getString('cancel'),
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _chatService.deleteMessage(_chatId, msg.id);
            },
            child: Text(lp.getString('delete'),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, bool isRecipientOnline,
      LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFFF4D85).withOpacity(0.15),
                  backgroundImage: widget.otherUserPhoto != null
                      ? NetworkImage(widget.otherUserPhoto!)
                      : null,
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint('Error loading chat profile image: $exception');
                  },
                  child: widget.otherUserPhoto == null
                      ? const Icon(Iconsax.user,
                          size: 10, color: Color(0xFFFF4D85))
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: isMe && !msg.isDeleted
                      ? () => _showActionMenu(msg, languageProvider)
                      : null,
                  child: _buildMessageContent(
                      msg, isMe, isRecipientOnline, languageProvider),
                ),
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
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage msg, bool isMe,
      bool isRecipientOnline, LanguageProvider languageProvider) {
    if (msg.isDeleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFFF4D85).withOpacity(0.4)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.info_circle,
                size: 14, color: isMe ? Colors.white70 : Colors.grey),
            const SizedBox(width: 8),
            Text(
              languageProvider.getString('message_deleted'),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (msg.messageType == MessageType.image && msg.mediaUrl != null) {
      return Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFF4D85) : Theme.of(context).cardColor,
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
                msg.mediaUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.withOpacity(0.1),
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey.withOpacity(0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined,
                            color: Colors.grey, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Image unavailable',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (msg.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : null,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (msg.messageType == MessageType.voice && msg.mediaUrl != null) {
      return _VoiceNoteBubble(url: msg.mediaUrl!, isMe: isMe);
    }

    // Default: Text message
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFF4D85) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            msg.text,
            style: TextStyle(
              color: isMe ? Colors.white : null,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          if (msg.isEdited) ...[
            const SizedBox(height: 2),
            Text(
              languageProvider.getString('edited_badge'),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTickMarks(ChatMessage msg, bool isRecipientOnline) {
    if (msg.isRead) {
      return const Icon(Icons.done_all, color: Colors.blue, size: 14);
    }
    return const Icon(Icons.done, color: Colors.grey, size: 14);
  }
}

// ─── Call Sheet Widget ───────────────────────────────────────────────────
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
    final languageProvider = context.watch<LanguageProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: photo != null ? NetworkImage(photo!) : null,
            child: photo == null ? const Icon(Iconsax.user, size: 40) : null,
          ),
          const SizedBox(height: 20),
          Text(isVideo ? 'Video Call' : 'Voice Call',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCallButton(Iconsax.close_circle, 'Cancel', Colors.red,
                  () => Navigator.pop(context), languageProvider),
              _buildCallButton(
                  isVideo ? Iconsax.video : Iconsax.call, 'Call', Colors.green,
                  () async {
                // Call logic
                Navigator.pop(context);
              }, languageProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton(IconData icon, String label, Color color,
      VoidCallback onTap, LanguageProvider languageProvider) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(languageProvider.getString(label.toLowerCase()),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
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

    final bubbleColor =
        widget.isMe ? const Color(0xFFFF4D85) : Theme.of(context).cardColor;
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
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
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
