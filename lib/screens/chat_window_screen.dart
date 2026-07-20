import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/report_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../services/photo_upload_service.dart';
import 'profile_detail_screen.dart';

class ChatWindowScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  final String? otherUserId;
  
  const ChatWindowScreen({super.key, required this.match, this.otherUserId});

  @override
  _ChatWindowScreenState createState() => _ChatWindowScreenState();
}

class _ChatWindowScreenState extends State<ChatWindowScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _otherUserId;
  Timer? _typingTimer;
  UserModel? _otherUser;
  bool _isSearching = false;
  String _searchQuery = '';
  ChatMessage? _replyingTo;
  File? _selectedPhoto;
  String? _uploadedPhotoUrl;
  bool _isUploading = false;
  bool _matchExists = true;
  bool _otherUserLeftChat = false;
  bool _otherUserAccountDeleted = false;
  bool _showSkeleton = false;
  Stream<List<ChatMessage>>? _messagesStream;
  
  final List<Color> avatarColors = [
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnlineStatus(true);
    
    // Use provided otherUserId or get from match data
    if (widget.otherUserId != null) {
      _otherUserId = widget.otherUserId;
    } else {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Check if this match has user IDs (from Firestore matches)
        if (widget.match.containsKey('user1Id') && widget.match.containsKey('user2Id')) {
          _otherUserId = widget.match['user1Id'] == currentUser.uid 
              ? widget.match['user2Id'] 
              : widget.match['user1Id'];
        } else {
          // For demo purposes, create a consistent ID based on the name
          _otherUserId = widget.match['name'].toString().replaceAll(' ', '_').toLowerCase();
        }
      }
    }
    
    _messageController.addListener(_onTyping);
    
    // Load other user's data and draft
    if (_otherUserId != null) {
      _loadOtherUserData();
      _loadDraft();
      _checkIfMatchExists();
    }
    
    _messagesStream = _otherUserId != null 
        ? ChatService.getMessages(_otherUserId!) 
        : Stream.value([]);
        
    Future.delayed(Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showSkeleton = true);
    });
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
        
        // Listen for chat deletion by other user
        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final deletedBy = snapshot.data()?['deletedBy'] as Map<String, dynamic>?;
            final otherUserDeleted = deletedBy?.containsKey(_otherUserId!) ?? false;
            if (_otherUserLeftChat != otherUserDeleted) {
              setState(() {
                _otherUserLeftChat = otherUserDeleted;
                _matchExists = !otherUserDeleted;
              });
            }
          }
        });
      }
    
    // Save draft when text changes
    _messageController.addListener(_saveDraft);
  }
  
  @override
  void dispose() {
    _setOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    _saveDraft();
    _typingTimer?.cancel();
    _messageController.removeListener(_onTyping);
    _messageController.removeListener(_saveDraft);
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
      // Mark messages as read when app becomes active
      _markVisibleMessagesAsRead();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _setOnlineStatus(false);
    }
  }
  
  void _setOnlineStatus(bool isOnline) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }
  
  void _onTyping() {
    if (_otherUserId == null) return;
    
    ChatService.setTyping(_otherUserId!, true);
    
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 2), () {
      ChatService.setTyping(_otherUserId!, false);
    });
  }
  
  void _markVisibleMessagesAsRead() async {
    if (_otherUserId == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
    
    try {
      await ChatService.markAsRead(chatId);
      print('✅ Marked visible messages as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching ? TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ) : Row(
          children: [
            GestureDetector(
              onTap: () => _navigateToUserProfile(),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _otherUserId == 'haule_official'
                        ? Colors.white
                        : (_otherUserId != null 
                            ? avatarColors[_otherUserId!.hashCode % avatarColors.length]
                            : Colors.white24),
                    backgroundImage: _otherUserId == 'haule_official'
                        ? AssetImage('assets/images/haule_logo.png') as ImageProvider
                        : _otherUserAccountDeleted
                            ? null
                            : (_otherUser?.profileImageUrl != null || _otherUser?.photoUrls?.isNotEmpty == true
                            ? CachedNetworkImageProvider(_otherUser!.profileImageUrl ?? _otherUser!.photoUrls!.first)
                            : widget.match['image'] != null
                            ? CachedNetworkImageProvider(widget.match['image'])
                            : null),
                    child: _otherUserId != 'haule_official' && 
                           (_otherUserAccountDeleted ||
                           (_otherUser?.profileImageUrl == null && 
                           _otherUser?.photoUrls?.isNotEmpty != true && 
                           widget.match['image'] == null))
                        ? Text(
                            _otherUserAccountDeleted ? 'D' : (widget.match['name'] ?? widget.match['firstName'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: StreamBuilder<bool>(
                      stream: _otherUserId != null ? _getOnlineStatus(_otherUserId!) : Stream.value(false),
                      builder: (context, snapshot) {
                        final isOnline = snapshot.data ?? false;
                        if (!isOnline || _otherUserAccountDeleted) return SizedBox.shrink();
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryColor, width: 2),
                          ),
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToUserProfile(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _otherUserAccountDeleted ? 'Deleted User' : (widget.match['name'] ?? widget.match['firstName'] ?? 'User'),
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (_otherUserId == 'haule_official') ...[
                          SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            color: Color(0xFFFFD700),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    StreamBuilder<bool>(
                      stream: _otherUserId != null ? _getOnlineStatus(_otherUserId!) : Stream.value(false),
                      builder: (context, snapshot) {
                        final isOnline = snapshot.data ?? false;
                        return Text(
                          isOnline ? 'ONLINE' : 'LAST SEEN RECENTLY',
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            elevation: 8,
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearChatDialog();
                  break;
                case 'delete':
                  _showDeleteChatDialog();
                  break;
                case 'block':
                  _showBlockDialog();
                  break;
                case 'report':
                  _showReportDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.clear_all, color: AppTheme.primaryColor, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text('Clear chat', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete_outline, color: AppTheme.primaryColor, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text('Delete chat', style: TextStyle(color: AppTheme.primaryColor, fontSize: 16)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.block, color: AppTheme.primaryColor, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text('Block user', style: TextStyle(color: AppTheme.primaryColor, fontSize: 16)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.report, color: AppTheme.primaryColor, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text('Report user', style: TextStyle(color: AppTheme.primaryColor, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],

      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                // Messages
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      print('📱 UI StreamBuilder state: ${snapshot.connectionState}');
                      print('   Has data: ${snapshot.hasData}');
                      print('   Data length: ${snapshot.data?.length ?? 0}');
                      print('   Has error: ${snapshot.hasError}');
                      if (snapshot.hasError) {
                        print('   Error: ${snapshot.error}');
                      }
                      
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        print('🔄 Showing loading skeleton');
                        return _showSkeleton ? _buildLoadingSkeleton() : const SizedBox();
                      }
                      
                      final messages = snapshot.data ?? [];
                      print('💬 Final UI messages count: ${messages.length}');
                      
                      if (messages.isEmpty) {
                        print('😭 Showing empty state');
                        return _buildEmptyState();
                      }
                      
                      // Mark messages as read when they become visible
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markVisibleMessagesAsRead();
                      });
                      
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final filteredMessages = messages.where((msg) {
                        // Hide photos that are still uploading if we are the receiver
                        final isMe = msg.senderId == currentUser?.uid;
                        if (!isMe && (msg.photoUrl == 'uploading' || msg.photoUrl == null) && msg.messageType == 'photo') {
                          return false; // Don't show to receiver until upload finishes
                        }
                        
                        // Apply search query filter if needed
                        if (_searchQuery.isNotEmpty) {
                          return msg.message.toLowerCase().contains(_searchQuery.toLowerCase());
                        }
                        
                        return true;
                      }).toList();
                      
                      print('🔍 Filtered messages count: ${filteredMessages.length}');
                      
                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        reverse: true,
                        itemCount: filteredMessages.length,
                        itemBuilder: (context, index) {
                          final message = filteredMessages[index];
                          
                          // Check if we need to show a date divider
                          bool showDateDivider = false;
                          if (index == filteredMessages.length - 1) {
                            showDateDivider = true; // Oldest message gets a divider
                          } else {
                            final nextMessage = filteredMessages[index + 1];
                            final currentDate = message.timestamp;
                            final nextDate = nextMessage.timestamp;
                            // Since reverse=true, nextMessage is older.
                            // If they are on different days, show divider above current message.
                            if (currentDate.day != nextDate.day || 
                                currentDate.month != nextDate.month || 
                                currentDate.year != nextDate.year) {
                              showDateDivider = true;
                            }
                          }
                          
                          Widget messageWidget = _buildSwipeableMessage(message);
                          
                          if (showDateDivider) {
                            return Column(
                              children: [
                                _buildDateDivider(message.timestamp),
                                messageWidget,
                              ],
                            );
                          }
                          
                          return messageWidget;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_replyingTo != null) _buildReplyPreview(),
          // Typing indicator above message input
          StreamBuilder<bool>(
            stream: _otherUserId != null ? ChatService.getTypingStatus(_otherUserId!) : Stream.value(false),
            builder: (context, snapshot) {
              final isTyping = snapshot.data ?? false;
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: isTyping ? 40 : 0,
                child: isTyping ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${widget.match['name'] ?? widget.match['firstName'] ?? 'User'} is typing',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return Container(
                            margin: EdgeInsets.only(right: index < 2 ? 2 : 0),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ) : null,
              );
            },
          ),
          if (_matchExists && !_otherUserAccountDeleted) _buildMessageInput(),
          if (!_matchExists || _otherUserAccountDeleted) Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Center(
              child: Text(
                _otherUserAccountDeleted 
                    ? 'This user has deleted their account'
                    : '${widget.match['name'] ?? 'User'} left the hangout',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _checkIfMatchExists() async {
    if (_otherUserId == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      // Check if other user deleted the chat
      final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      
      bool otherUserDeleted = false;
      if (chatDoc.exists) {
        final deletedBy = chatDoc.data()?['deletedBy'] as Map<String, dynamic>?;
        otherUserDeleted = deletedBy?.containsKey(_otherUserId!) ?? false;
      }
      
      if (mounted) {
        setState(() {
          _otherUserLeftChat = otherUserDeleted;
          _matchExists = !otherUserDeleted;
        });
      }
    } catch (e) {
      print('Error checking match: $e');
    }
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'TODAY';
    } else if (messageDate == yesterday) {
      return 'YESTERDAY';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildDateDivider(DateTime date) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 24),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _formatDateSeparator(date),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwipeableMessage(ChatMessage message) {
    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Icon(Icons.reply, color: AppTheme.primaryColor),
      ),
      confirmDismiss: (direction) async {
        setState(() {
          _replyingTo = message;
        });
        return false;
      },
      child: _buildMessage(message),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMe = message.senderId == currentUser?.uid;
    
    return GestureDetector(
      onLongPress: message.messageType == 'deleted' ? null : () => _showMessageOptions(message, isMe),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              message.messageType == 'photo' 
                  ? _buildPhotoMessage(message, isMe)
                  : message.messageType == 'location'
                  ? _buildLocationMessage(message, isMe)
                  : Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        IntrinsicWidth(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? AppTheme.primaryColor : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(isMe ? 20 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isMe 
                                      ? AppTheme.primaryColor.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Reply preview
                                if (message.replyToMessage != null)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: isMe ? Colors.white.withOpacity(0.5) : AppTheme.primaryColor,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            message.replyToMessage!,
                                            style: TextStyle(
                                              color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                message.messageType == 'gif'
                                    ? _buildGifMessage(message, isMe)
                                    : message.messageType == 'deleted'
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.block,
                                                size: 16,
                                                color: isMe ? Colors.white70 : Colors.black54,
                                              ),
                                              SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  message.message,
                                                  style: TextStyle(
                                                    color: isMe ? Colors.white70 : Colors.black54,
                                                    fontSize: 15,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            message.message,
                                            style: TextStyle(
                                              color: isMe ? Colors.white : Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                              height: 1.4,
                                            ),
                                          ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isMe) ...[
                              SizedBox(width: 4),
                              Icon(
                                message.photoUrl == 'uploading' ? Icons.access_time :
                                message.status == 'read' ? Icons.done_all : 
                                message.status == 'delivered' ? Icons.done_all : Icons.done,
                                size: 14,
                                color: message.photoUrl == 'uploading' ? Colors.grey[400] : AppTheme.primaryColor,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
              // Reactions - temporarily disabled for launch
              // if (message.reactions.isNotEmpty)
              //   Container(
              //     margin: EdgeInsets.only(top: 4),
              //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //     decoration: BoxDecoration(
              //       color: Colors.grey[200],
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: message.reactions.entries.map((entry) => 
              //         Padding(
              //           padding: EdgeInsets.only(right: 4),
              //           child: Text(entry.value, style: TextStyle(fontSize: 16)),
              //         )
              //       ).toList(),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showMessageOptions(ChatMessage message, bool isMe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  bottom: 48, // Massive padding to guarantee clearance
                  top: 16, left: 16, right: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reactions - temporarily disabled for launch
                    // FittedBox(
                    //   fit: BoxFit.scaleDown,
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //     children: ['❤️', '😂', '😮', '😢', '😡', '👍'].map((emoji) => 
                    //       GestureDetector(
                    //         onTap: () {
                    //           ChatService.addReaction(_otherUserId!, message.id, emoji);
                    //           Navigator.pop(context);
                    //         },
                    //         child: Container(
                    //           padding: EdgeInsets.all(12),
                    //           child: Text(emoji, style: TextStyle(fontSize: 24)),
                    //         ),
                    //       )
                    //     ).toList(),
                    //   ),
                    // ),
                    // Divider(),
                    // Delete options
                    if (isMe) ...[
                      ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete for me'),
                        onTap: () {
                          _deleteMessage(message.id, false);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_forever, color: Colors.red),
                        title: Text('Delete for everyone'),
                        onTap: () {
                          _deleteMessage(message.id, true);
                          Navigator.pop(context);
                        },
                      ),
                    ] else ...[
                      ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete for me'),
                        onTap: () {
                          _deleteMessage(message.id, false);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteMessage(String messageId, bool deleteForEveryone) async {
    try {
      if (deleteForEveryone) {
        await ChatService.deleteMessageForEveryone(_otherUserId!, messageId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message deleted for everyone')),
        );
      } else {
        await ChatService.deleteMessageForMe(_otherUserId!, messageId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message deleted for you')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMessageInput() {
    if (_otherUserLeftChat) {
      return SafeArea(
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
              SizedBox(width: 8),
              Text(
                'User left the chat',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 24,
          top: 8,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file, color: Colors.grey[500]),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 40),
                onPressed: () {
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              IconButton(
                icon: Icon(Icons.location_on_outlined, color: Colors.grey[500]),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 40),
                onPressed: _shareLocation,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedPhoto != null)
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        height: 54,
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_selectedPhoto!, width: 50, height: 50, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () => setState(() { _selectedPhoto = null; _uploadedPhotoUrl = null; }),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black12, blurRadius: 4),
                                        ],
                                      ),
                                      child: Icon(Icons.cancel, size: 20, color: Colors.grey[700]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Photo selected',
                                style: TextStyle(
                                  color: Colors.grey[600], 
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _messageController,
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: _selectedPhoto != null ? 'Add a caption...' : 'Message...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.sentiment_satisfied_alt, color: Colors.grey[500]),
                onPressed: _showEmojiGifPicker,
              ),
              GestureDetector(
                onTap: _isUploading ? null : _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isUploading ? Colors.grey : AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploading
                      ? Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() async {
    if ((_messageController.text.trim().isEmpty && _selectedPhoto == null) || _otherUserId == null) return;

    final messageText = _messageController.text.trim();
    final photo = _selectedPhoto;
    final replyTo = _replyingTo;
    
    // Clear UI immediately (WhatsApp style)
    _messageController.clear();
    _clearDraft();
    setState(() {
      _replyingTo = null;
      _selectedPhoto = null;
      _uploadedPhotoUrl = null;
    });

    try {
      if (photo != null) {
        // Send message immediately with local photo path
        final messageId = await ChatService.sendMessageWithId(
          receiverId: _otherUserId!,
          message: messageText.isEmpty ? 'Photo' : messageText,
          messageType: 'photo',
          photoUrl: 'uploading',
          localPhotoPath: photo.path, // Local file path
          replyToId: replyTo?.id,
          replyToMessage: replyTo?.message,
        );
        
        // Upload in background and update
        _uploadPhotoInBackground(photo, messageId);
      } else {
        await ChatService.sendMessage(
          receiverId: _otherUserId!,
          message: messageText,
          replyToId: replyTo?.id,
          replyToMessage: replyTo?.message,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _uploadPhotoInBackground(File photo, String messageId) async {
    try {
      final photoUrl = await PhotoUploadService.uploadChatPhoto(photo);
      if (photoUrl != null) {
        // Update the message with actual photo URL and clear local path
        await ChatService.updateMessagePhotoComplete(_otherUserId!, messageId, photoUrl);
      }
    } catch (e) {
      print('Background upload failed: $e');
    }
  }

  Future<void> _loadOtherUserData() async {
    if (_otherUserId == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_otherUserId!)
          .get();
      
      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        setState(() {
          _otherUser = UserModel.fromMap(data);
          _otherUserAccountDeleted = data['isDeleted'] == true;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(bottom: 8),
            width: MediaQuery.of(context).size.width * 0.6,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start the conversation with ${widget.match['name'] ?? widget.match['firstName'] ?? 'User'}!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _replyingTo!.message,
                  style: TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Stream<bool> _getOnlineStatus(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final data = doc.data()!;
      
      // Check if user is explicitly online
      final isOnline = data['isOnline'] as bool?;
      if (isOnline == true) return true;
      
      // Fallback to lastSeen check
      final lastSeen = data['lastSeen'] as Timestamp?;
      if (lastSeen == null) return false;
      
      final now = DateTime.now();
      final lastSeenTime = lastSeen.toDate();
      return now.difference(lastSeenTime).inMinutes < 2;
    });
  }

  void _saveDraft() async {
    if (_otherUserId == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
    final draft = _messageController.text.trim();
    
    try {
      if (draft.isNotEmpty) {
        // Ensure chat document exists with participants before updating draft
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .set({
          'participants': [currentUser.uid, _otherUserId!],
          'draft_${currentUser.uid}': draft,
        }, SetOptions(merge: true));
      } else {
        // Only try to delete draft if document exists
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();
        
        if (chatDoc.exists) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .update({
            'draft_${currentUser.uid}': FieldValue.delete(),
          });
        }
      }
    } catch (e) {
      print('Error saving draft: $e');
      // Don't rethrow as draft saving is not critical
    }
  }
  
  void _loadDraft() async {
    if (_otherUserId == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
    
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        final draft = data['draft_${currentUser.uid}'] as String?;
        
        if (draft != null && draft.isNotEmpty && mounted) {
          _messageController.text = draft;
        }
      }
    } catch (e) {
      print('Error loading draft: $e');
    }
  }
  
  void _clearDraft() async {
    if (_otherUserId == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
    
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'draft_${currentUser.uid}': FieldValue.delete(),
      });
    } catch (e) {
      print('Error clearing draft: $e');
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear chat'),
        content: Text('Are you sure you want to clear all messages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _clearChat();
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.red.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.red.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Chat',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this chat? This will only delete the chat for you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _deleteChat();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${widget.match['name']}'),
        content: Text('Blocked users cannot send you messages or see your profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _blockUser();
              Navigator.pop(context);
            },
            child: Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final reasons = [
      'Inappropriate messages',
      'Harassment or bullying',
      'Spam or scam',
      'Fake profile',
      'Inappropriate photos',
      'Threatening behavior',
      'Other'
    ];
    
    String? selectedReason;
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.red.withOpacity(0.05),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.report,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Report ${widget.match['name']}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Why are you reporting this user?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...reasons.map((reason) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedReason == reason ? AppTheme.primaryColor : Colors.grey[300]!,
                      ),
                      color: selectedReason == reason ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                    ),
                    child: RadioListTile<String>(
                      title: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedReason == reason ? AppTheme.primaryColor : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: reason,
                      groupValue: selectedReason,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (value) => setState(() => selectedReason = value),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  )),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Additional details (optional)',
                      hintText: 'Describe the issue...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                      labelStyle: TextStyle(color: AppTheme.primaryColor),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedReason != null ? () {
                            _submitReport(selectedReason!, descriptionController.text);
                            Navigator.pop(context);
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteChat() async {
    if (_otherUserId == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
    
    try {
      // Set deletedBy timestamp for current user
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'deletedBy': {
          currentUser.uid: FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      
      // Delete match for both users
      final matchQuery = await FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'active')
          .get();
      
      for (final doc in matchQuery.docs) {
        final data = doc.data();
        final participants = [data['user1Id'], data['user2Id']];
        if (participants.contains(currentUser.uid) && participants.contains(_otherUserId)) {
          await doc.reference.delete();
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat deleted')),
      );
      
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearChat() async {
    if (_otherUserId == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
    
    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _blockUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.match['name']} has been blocked')),
    );
  }

  void _submitReport(String reason, String description) async {
    if (_otherUserId == null) return;
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
      
      await ReportService.reportUser(
        reportedUserId: _otherUserId!,
        reason: reason,
        description: description,
        chatId: chatId,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report submitted. We\'ll review it within 24 hours.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareLocation() async {
    if (_otherUserId == null) return;
    
    // Show confirmation dialog first
    final shouldShare = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppTheme.primaryColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Share Location',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Do you want to share your current location with ${widget.match['name'] ?? 'this user'}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (shouldShare != true) return;
    
    // Show loading snackbar immediately
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Getting your location...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        elevation: 8,
        duration: Duration(seconds: 10),
      ),
    );
    
    // Process location sharing asynchronously
    _processLocationSharing();
  }
  
  void _navigateToUserProfile() {
    if (_otherUserId == null || _otherUserId == 'haule_official' || _otherUserAccountDeleted) return;
    
    // Navigate to ProfileDetailScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          user: {
            'uid': _otherUserId,
            'userId': _otherUserId,
            'firstName': widget.match['name'] ?? widget.match['firstName'] ?? 'User',
            'lastName': widget.match['lastName'] ?? '',
            'age': widget.match['age'],
            'gender': widget.match['gender'],
            'profileImageUrl': _otherUser?.profileImageUrl ?? widget.match['image'],
            'photoUrls': _otherUser?.photoUrls ?? [],
            'interests': _otherUser?.interests ?? [],
            'occupation': _otherUser?.occupation,
            'education': _otherUser?.education,
            'religion': _otherUser?.religion,
            'ethnicity': _otherUser?.ethnicity,
            'height': _otherUser?.height,
            ..._otherUser?.toMap() ?? {},
            ...widget.match,
          },
          showChatButton: true,
        ),
      ),
    );
  }

  void _processLocationSharing() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Location permission denied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
              elevation: 8,
            ),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_off, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Location permission permanently denied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            elevation: 8,
          ),
        );
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      String locationName = 'Current Location';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          locationName = '${place.locality ?? ''} ${place.country ?? ''}'.trim();
          if (locationName.isEmpty) locationName = 'Current Location';
        }
      } catch (e) {
        // Use default name if geocoding fails
      }
      
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Send location message
      await ChatService.sendMessage(
        receiverId: _otherUserId!,
        message: 'Shared location',
        messageType: 'location',
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
      );
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'Location shared successfully',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          elevation: 8,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error getting location: $e',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          elevation: 8,
        ),
      );
    }
  }
  
  Widget _buildLocationMessage(ChatMessage message, bool isMe) {
    return GestureDetector(
      onTap: () => _openLocation(message.latitude!, message.longitude!),
      child: Container(
        width: 250,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? AppTheme.primaryColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 250,
                height: 200,
                color: Color(0xFF2C2C2C),
                child: Stack(
                  children: [
                    // Simulated dark map background
                    Container(
                      width: 250,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A1A1A),
                            Color(0xFF2C2C2C),
                            Color(0xFF1F1F1F),
                          ],
                        ),
                      ),
                    ),
                    // Road-like patterns
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        color: Color(0xFF404040),
                      ),
                    ),
                    Positioned(
                      top: 120,
                      left: 80,
                      right: 0,
                      child: Container(
                        height: 3,
                        color: Color(0xFF505050),
                      ),
                    ),
                    // Location marker
                    Positioned(
                      top: 85,
                      left: 115,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    // Google logo
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Text(
                        'Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 4),
                      Icon(
                        message.status == 'read' ? Icons.done_all : 
                        message.status == 'delivered' ? Icons.done_all : Icons.done,
                        size: 12,
                        color: message.status == 'read' ? Colors.blue : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _openLocation(double latitude, double longitude) async {
    try {
      final url = 'https://www.google.com/maps/@$latitude,$longitude,15z';
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location: $latitude, $longitude')),
      );
    }
  }

  void _showEmojiGifPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              TabBar(
                tabs: [
                  Tab(text: 'Emojis'),
                  Tab(text: 'GIFs'),
                ],
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                labelStyle: TextStyle(fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      child: GridView.count(
                        crossAxisCount: 8,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          '😀', '😂', '🥰', '😍', '🤔', '😎', '😴', '🤤',
                          '❤️', '💙', '💚', '💛', '🧡', '💜', '🖤', '🤍',
                          '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '👏',
                          '🔥', '💯', '✨', '⭐', '🌟', '💫', '🎉', '🎊',
                          '😭', '😱', '🤯', '🥳', '🤩', '😇', '🤗', '🤭',
                          '😘', '😋', '🤪', '😜', '🙃', '😌', '😊', '☺️',
                          '🥺', '😤', '😡', '🤬', '😈', '👿', '💀', '☠️',
                          '🤡', '👻', '👽', '🤖', '💩', '🔥', '💥', '💢',
                          '💨', '💦', '💤', '🗯️', '💭', '🗨️', '💬', '💌',
                          '💕', '💖', '💗', '💘', '💝', '💟', '♥️', '💔',
                          '🙏', '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤏',
                          '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆',
                          '🖕', '👇', '☝️', '👍', '👎', '👊', '✊', '🤛',
                          '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️',
                          '💪', '🦾', '🦿', '🦵', '🦶', '👂', '🦻', '👃',
                        ].map((emoji) => GestureDetector(
                          onTap: () {
                            _messageController.text += emoji;
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(emoji, style: TextStyle(fontSize: 28)),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif',
                          'https://media.giphy.com/media/26u4cqiYI30juCOGY/giphy.gif',
                          'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif',
                          'https://media.giphy.com/media/3o6Zt481isNVuQI1l6/giphy.gif',
                        ].map((gifUrl) => GestureDetector(
                          onTap: () {
                            _sendGif(gifUrl);
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                gifUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  Container(
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.gif, size: 40, color: AppTheme.primaryColor),
                                          SizedBox(height: 8),
                                          Text('GIF', style: TextStyle(color: AppTheme.primaryColor)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _sendGif(String gifUrl) async {
    if (_otherUserId == null) return;
    
    try {
      await ChatService.sendMessage(
        receiverId: _otherUserId!,
        message: 'GIF',
        messageType: 'gif',
        gifUrl: gifUrl,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending GIF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildGifMessage(ChatMessage message, bool isMe) {
    return Container(
      constraints: BoxConstraints(maxWidth: 200, maxHeight: 200),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          message.gifUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => 
            Container(
              width: 200,
              height: 100,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.grey),
                  Text('GIF not available', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ),
      ),
    );
  }

  void _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _selectedPhoto = File(pickedFile.path);
        _uploadedPhotoUrl = null;
      });
    }
  }

  Widget _buildPhotoMessage(ChatMessage message, bool isMe) {
    final bool hasCaption = message.message.isNotEmpty && message.message != 'Photo';

    // Helper function to build the time overlay
    Widget buildTimeOverlay(bool isOverlayOnImage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: isOverlayOnImage ? Colors.white : (isMe ? Colors.white70 : Colors.grey[600]), 
              fontSize: 11
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 4),
            Icon(
              message.photoUrl == 'uploading' ? Icons.access_time :
              message.status == 'read' ? Icons.done_all : 
              message.status == 'delivered' ? Icons.done_all : Icons.done,
              size: 12,
              color: isOverlayOnImage 
                  ? (message.photoUrl == 'uploading' ? Colors.white70 : message.status == 'read' ? Colors.blue : Colors.white70)
                  : (message.photoUrl == 'uploading' ? Colors.white54 : message.status == 'read' ? Colors.blue[200] : Colors.white70),
            ),
          ],
        ],
      );
    }

    Widget buildImageContent(Widget imageWidget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(10),
                  bottom: Radius.circular(hasCaption ? 0 : 10),
                ),
                child: imageWidget,
              ),
              if (!hasCaption)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: buildTimeOverlay(true),
                  ),
                ),
              if (message.photoUrl == 'uploading')
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (hasCaption)
            Container(
              width: 250,
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: buildTimeOverlay(false),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    // Only show local photo for the sender to prevent PathNotFoundException on receiver
    if (isMe && message.localPhotoPath != null && message.photoUrl == 'uploading') {
      return GestureDetector(
        onTap: () => _showImageViewer(message.localPhotoPath!, isLocal: true),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 254),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          child: buildImageContent(
            Image.file(
              File(message.localPhotoPath!),
              width: 250,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 250,
                height: 250,
                color: Colors.grey[100],
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // If it's still uploading but we are the receiver (or sender lost the local file)
    if (message.photoUrl == 'uploading' || message.photoUrl == null) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? AppTheme.primaryColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Receiving photo...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback to network image
    return GestureDetector(
      onTap: () => _showImageViewer(message.photoUrl!),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 254),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? AppTheme.primaryColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: buildImageContent(
          CachedNetworkImage(
            imageUrl: message.photoUrl!,
            width: 250,
            height: 250,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 250,
              height: 250,
              color: Colors.grey[100],
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 250,
              height: 250,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_not_supported, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Photo unavailable', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
  
  void _showImageViewer(String imagePath, {bool isLocal = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imagePath: imagePath,
          isLocal: isLocal,
        ),
      ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  final bool isLocal;
  
  const ImageViewerScreen({
    super.key,
    required this.imagePath,
    this.isLocal = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: isLocal
                ? Image.file(
                    File(imagePath),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[800],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.white, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Image not available',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  )
                : Image.network(
                    imagePath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[800],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.white, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Image not available',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

