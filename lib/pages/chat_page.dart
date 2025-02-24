import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:whispr_chat_app/components/emoji_picker_panel.dart';
import 'package:whispr_chat_app/models/message.dart';
import 'package:whispr_chat_app/services/auth/auth_service.dart';
import 'package:whispr_chat_app/services/chat/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:whispr_chat_app/themes/app_theme.dart';
import 'package:whispr_chat_app/themes/custom_color.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  String? _receiverUsername;
  String? _profileImageUrl;
  Message? _replyMessage;

  bool _showEmojiPicker = false;
  bool _isKeyboardVisible = false;
  late FocusNode _focusNode;

  bool _isSelectionMode = false;
  Set<String> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _showEmojiPicker = false;
        _isKeyboardVisible = true;
      });
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      if (_isKeyboardVisible) {
        FocusScope.of(context).unfocus();
        Future.delayed(Duration(milliseconds: 200), () {
          setState(() {
            _showEmojiPicker = true;
          });
        });
      } else {
        _showEmojiPicker = !_showEmojiPicker;
      }
      _isKeyboardVisible = false;
    });
  }

  void _onEmojiSelected(String emoji) {
    setState(() {
      final currentText = _messageController.text;
      final textSelection = _messageController.selection;
      final newText = currentText.replaceRange(
        textSelection.start,
        textSelection.end,
        emoji,
      );
      final emojiLength = emoji.length;
      _messageController.text = newText;
      _messageController.selection = TextSelection.collapsed(
        offset: textSelection.baseOffset + emojiLength,
      );
    });
  }

  void _selectAllMessages(List<QueryDocumentSnapshot> messages) {
    setState(() {
      _isSelectionMode = true;
      _selectedMessageIds = messages.map((doc) => doc.id).toSet();
    });
  }

  void _loadUserDetails() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverID)
          .get();

      if (userDoc.exists) {
        final username = userDoc.get('username') ?? widget.receiverEmail;

        setState(() {
          _receiverUsername = username;
          _profileImageUrl = userDoc.get('profileImageUrl');
        });

        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.receiverID)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            setState(() {
              _receiverUsername =
                  snapshot.get('username') ?? widget.receiverEmail;
            });
          }
        });
      }
    } catch (e) {
      print('Error loading user details: $e');
      setState(() {
        _receiverUsername = widget.receiverEmail;
      });
    }
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(messageId);
        _isSelectionMode = true;
      }
    });
  }

  void _handleReplyMessage(Message message) {
    setState(() {
      _replyMessage = message;
    });
    _messageController.text = '';
    FocusScope.of(context).requestFocus(FocusNode());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Replying to message'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: _cancelReply,
        ),
      ),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyMessage = null;
    });
  }

  Future<void> _deleteSelectedMessages() async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete ${_selectedMessageIds.length} selected messages?',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                icon: Icons.delete_forever,
                title: 'Delete for everyone',
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteMultipleMessages(true);
                },
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                icon: Icons.delete,
                title: 'Delete for me',
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteMultipleMessages(false);
                },
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                icon: Icons.close,
                title: 'Cancel',
                onTap: () => Navigator.pop(context),
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMultipleMessages(bool forEveryone) async {
    try {
      List<String> ids = [
        _authService.getCurrentUser()!.uid,
        widget.receiverID
      ];
      ids.sort();
      String chatRoomID = ids.join("_");

      for (String messageId in _selectedMessageIds) {
        if (forEveryone) {
          await FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(chatRoomID)
              .collection('messages')
              .doc(messageId)
              .delete();
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_authService.getCurrentUser()!.uid)
              .collection('deleted_messages')
              .doc(messageId)
              .set({
            'chatRoomID': chatRoomID,
            'deletedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      setState(() {
        _selectedMessageIds.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Messages deleted ${forEveryone ? 'for everyone' : 'for me'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting messages: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteMessage(Message message, bool forEveryone) async {
    try {
      List<String> ids = [
        _authService.getCurrentUser()!.uid,
        widget.receiverID
      ];
      ids.sort();
      String chatRoomID = ids.join("_");

      if (forEveryone) {
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(chatRoomID)
            .collection('messages')
            .doc(message.id)
            .delete();
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_authService.getCurrentUser()!.uid)
            .collection('deleted_messages')
            .doc(message.id)
            .set({
          'chatRoomID': chatRoomID,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Message deleted ${forEveryone ? 'for everyone' : 'for me'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDeleteDialog(Message message, bool isCurrentUser) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Message',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              if (isCurrentUser) ...[
                _buildActionButton(
                  context,
                  icon: Icons.delete,
                  title: 'Delete for me',
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, false);
                  },
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  context,
                  icon: Icons.delete_forever,
                  title: 'Delete for everyone',
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, true);
                  },
                  color: Theme.of(context).colorScheme.error,
                ),
              ] else
                _buildActionButton(
                  context,
                  icon: Icons.delete,
                  title: 'Delete for me',
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, false);
                  },
                  color: Theme.of(context).colorScheme.error,
                ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                icon: Icons.close,
                title: 'Cancel',
                onTap: () => Navigator.pop(context),
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        final timestamp = Timestamp.now();
        final String messageId =
            '${timestamp.seconds}-${timestamp.nanoseconds}-${DateTime.now().microsecond}';

        Map<String, dynamic>? replyToMap;
        if (_replyMessage != null) {
          replyToMap = {
            'id': _replyMessage!.id,
            'senderID': _replyMessage!.senderID,
            'senderEmail': _replyMessage!.senderEmail,
            'receiverID': _replyMessage!.receiverID,
            'message': _replyMessage!.message,
            'time': _replyMessage!.time,
            'timestamp': _replyMessage!.timestamp,
            'read': _replyMessage!.read,
          };
        }

        Map<String, dynamic> messageData = {
          'id': messageId,
          'message': _messageController.text,
          'replyTo': replyToMap,
        };

        await _chatService.sendMessage(widget.receiverID, messageData);
        _messageController.clear();
        setState(() => _replyMessage = null);

        if (!_isSelectionMode && _scrollController.hasClients) {
          await _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        print('Detailed error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(),
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_replyMessage != null) _buildReplyPreview(),
            _buildMessageInput(),
            if (_showEmojiPicker)
              CustomEmojiPanel(
                onEmojiSelected: _onEmojiSelected,
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
        toolbarHeight: 50,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(
            padding: const EdgeInsets.only(left: 10, right: 4, bottom: 16),
            child: Row(
              children: [
                _isSelectionMode
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _selectedMessageIds.clear();
                            _isSelectionMode = false;
                          });
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                const SizedBox(width: 12),
                if (!_isSelectionMode) ...[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
                        ? Text(
                            (_receiverUsername ?? '')[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _receiverUsername ?? '',
                          style: GoogleFonts.museoModerno(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Offline',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      '${_selectedMessageIds.length} Selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_isSelectionMode) ...[
                  IconButton(
                    icon: const Icon(Icons.select_all, color: Colors.white),
                    onPressed: () {
                      _chatService
                          .getMessages(
                            _authService.getCurrentUser()!.uid,
                            widget.receiverID,
                          )
                          .first
                          .then(
                              (snapshot) => _selectAllMessages(snapshot.docs));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: _deleteSelectedMessages,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(
        _authService.getCurrentUser()!.uid,
        widget.receiverID,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading messages'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            return _isSelectionMode;
          },
          child: Theme(
            data: Theme.of(context).copyWith(
              scrollbarTheme: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  try {
                    var messageData =
                        messages[index].data() as Map<String, dynamic>;
                    var currentMessage =
                        Message.fromMap(messageData, messages[index].id);

                    Widget spacingWidget = const SizedBox.shrink();
                    if (index < messages.length - 1) {
                      var nextMessageData =
                          messages[index + 1].data() as Map<String, dynamic>;
                      var nextMessage = Message.fromMap(
                          nextMessageData, messages[index + 1].id);

                      Duration timeDiff = currentMessage.time
                          .toDate()
                          .difference(nextMessage.time.toDate());

                      if (timeDiff.inMinutes > 0 ||
                          currentMessage.senderID != nextMessage.senderID) {
                        spacingWidget = const SizedBox(height: 8);
                      } else {
                        spacingWidget = const SizedBox(height: 4);
                      }
                    }

                    return Column(
                      children: [
                        _buildMessageItem(currentMessage),
                        spacingWidget,
                      ],
                    );
                  } catch (e) {
                    print('Error building message item: $e');
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessageActions(Message message, bool isCurrentUser) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Message Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              icon: Icons.reply,
              title: 'Reply',
              onTap: () {
                Navigator.pop(context);
                _handleReplyMessage(message);
              },
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              icon: Icons.delete,
              title: 'Delete',
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(message, isCurrentUser);
              },
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              icon: Icons.select_all,
              title: 'Select Messages',
              onTap: () {
                Navigator.pop(context);
                _toggleMessageSelection(message.id);
              },
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              icon: Icons.close,
              title: 'Cancel',
              onTap: () => Navigator.pop(context),
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    final bool isCurrentUser =
        message.senderID == _authService.getCurrentUser()!.uid;
    final String time = DateFormat('HH:mm').format(message.time.toDate());
    final bool isSelected = _selectedMessageIds.contains(message.id);

    final theme = Theme.of(context);
    final currentUserBubbleColor = isSelected
        ? theme.colorScheme.primary.withOpacity(0.08)
        : theme.colorScheme.primary;

    final customColors = Theme.of(context).extension<CustomColors>()!;
    final otherUserBubbleColor = isSelected
        ? customColors.quaternary!.withOpacity(0.01)
        : customColors.quaternary!;
        
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: GestureDetector(
        onTap: () {
          if (_isSelectionMode) {
            final currentPosition = _scrollController.position.pixels;
            _toggleMessageSelection(message.id);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentPosition);
              }
            });
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            final currentPosition = _scrollController.position.pixels;
            _showMessageActions(message, isCurrentUser);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentPosition);
              }
            });
          }
        },
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (isSelected)
                  Container(
                    width: 3,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: EdgeInsets.only(
                      top: 1,
                      bottom: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.08)
                          : (isCurrentUser
                              ? currentUserBubbleColor
                              : otherUserBubbleColor),
                      borderRadius: BorderRadius.only(
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                        topLeft: Radius.circular(isCurrentUser ? 16 : 4),
                        topRight: Radius.circular(isCurrentUser ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.replyTo != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.12)
                                  : (isCurrentUser
                                      ? theme.colorScheme.surface
                                          .withOpacity(0.2)
                                      : theme.colorScheme.primary
                                          .withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : (isCurrentUser
                                            ? Colors.white
                                            : theme.colorScheme.primary),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.replyTo?.message ?? '',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black87
                                        : (isCurrentUser
                                            ? Colors.white.withOpacity(0.9)
                                            : theme.colorScheme.primary),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                message.message,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black87
                                      : (isCurrentUser
                                          ? Colors.white
                                          : (theme.brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black87)),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              time,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black87.withOpacity(0.7)
                                    : (isCurrentUser
                                        ? Colors.white.withOpacity(0.7)
                                        : const Color.fromARGB(
                                            255, 173, 173, 173)),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_replyMessage?.senderID)
                      .get(),
                  builder: (context, snapshot) {
                    bool isCurrentUser = _replyMessage?.senderID ==
                        _authService.getCurrentUser()!.uid;
                    String displayName = 'You';
                    if (!isCurrentUser && snapshot.hasData) {
                      displayName = snapshot.data?['username'] ?? 'User';
                    }
                    return Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
                Text(
                  _replyMessage?.message ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  prefixIcon: IconButton(
                    icon: Icon(
                      _showEmojiPicker
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                      color: theme.colorScheme.primary, // Use primary color
                    ),
                    onPressed: _toggleEmojiPicker,
                  ),
                ),
                maxLines: null,
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
