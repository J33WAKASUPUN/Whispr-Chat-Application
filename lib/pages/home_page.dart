import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:whispr_chat_app/services/auth/auth_service.dart';
import 'package:whispr_chat_app/services/chat/chat_service.dart';
import 'package:whispr_chat_app/components/my_drawer.dart';
import 'package:whispr_chat_app/pages/chat_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whispr_chat_app/themes/custom_color.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterSearchResults(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _searchResults = _allUsers.where((user) {
          final username = (user['username'] ?? '').toLowerCase();
          final email = (user['email'] ?? '').toLowerCase();
          final searchQuery = query.toLowerCase();
          return username.contains(searchQuery) || email.contains(searchQuery);
        }).toList();
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _filterSearchResults,
              ),
            ),
            // Users list
            Expanded(
              child: StreamBuilder(
                stream: widget._chatService.getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  _allUsers = snapshot.data ?? [];
                  final usersToDisplay = _searchController.text.isEmpty
                      ? _allUsers
                      : _searchResults;

                  return ListView.builder(
                    itemCount: usersToDisplay.length,
                    itemBuilder: (context, index) {
                      final userData = usersToDisplay[index];
                      if (userData['email'] !=
                          widget._authService.getCurrentUser()!.email) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Text(
                              (userData['username'] ??
                                      userData['email'] ??
                                      'U')[0]
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            userData['username'] ??
                                userData['email'] ??
                                'Unknown User',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  receiverEmail: userData['email'],
                                  receiverID: userData['uid'],
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return Container();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
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
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary),
                            decoration: InputDecoration(
                              hintText: 'Search chats...',
                              hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.5)),
                              border: InputBorder.none,
                            ),
                            onChanged: _filterSearchResults,
                          )
                        : Text(
                            'Whispr',
                            style: GoogleFonts.museoModerno(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          _searchResults.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          // Recent chats header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chats',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                      ),
                ),
              ],
            ),
          ),
          // Chat list
          Expanded(
            child: StreamBuilder(
              stream: widget._chatService.getSortedChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final usersToDisplay =
                    _isSearching ? _searchResults : snapshot.data!;

                return Theme(
                  data: Theme.of(context).copyWith(
                    scrollbarTheme: ScrollbarThemeData(
                      thumbColor: MaterialStateProperty.all(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: usersToDisplay.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final userData = usersToDisplay[index];
                        if (userData['email'] !=
                            widget._authService.getCurrentUser()!.email) {
                          return _buildChatTile(userData, context);
                        }
                        return Container();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: _showNewChatDialog,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chatData, BuildContext context) {
    final currentUserID = widget._authService.getCurrentUser()!.uid;
    final bool isOnline = chatData['isOnline'] ?? false;
    final lastMessage = chatData['lastMessage'];
    final customColors = Theme.of(context).extension<CustomColors>()!;

    String getFormattedDate(DateTime date) {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == DateTime(now.year, now.month, now.day)) {
        return DateFormat('HH:mm').format(date);
      } else if (messageDate == yesterday) {
        return 'Yesterday';
      } else {
        return DateFormat('dd/MM/yy').format(date);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: customColors.quaternary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () async {
          List<String> ids = [currentUserID, chatData['uid']];
          ids.sort();
          String chatRoomID = ids.join("_");
          await widget._chatService.markMessagesAsRead(chatRoomID);

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverEmail: chatData['email'],
                receiverID: chatData['uid'],
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(
            (chatData['username'] ?? chatData['email'] ?? 'U')[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chatData['username'] ?? chatData['email'] ?? 'Unknown User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lastMessage != null)
              Text(
                getFormattedDate(
                  DateTime.fromMillisecondsSinceEpoch(lastMessage['timestamp']),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage == null
                    ? 'Tap to start conversation'
                    : lastMessage['senderID'] == currentUserID
                        ? 'You: ${lastMessage['message']}'
                        : lastMessage['message'],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: lastMessage != null &&
                          lastMessage['read'] == false &&
                          lastMessage['senderID'] != currentUserID
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            StreamBuilder<int>(
              stream: widget._chatService.getUnreadMessageCount(
                currentUserID,
                chatData['uid'],
              ),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                if (unreadCount == 0) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.transparent,
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
