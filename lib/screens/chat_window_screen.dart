import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/photo_upload_service.dart';

class ChatWindowScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  final String? otherUserId;
  
  const ChatWindowScreen({super.key, required this.match, this.otherUserId});

  @override
  _ChatWindowScreenState createState() => _ChatWindowScreenState();
}

class _ChatWindowScreenState extends State<ChatWindowScreen> {
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
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
        ChatService.markAsRead(chatId);
      }
    }
    
    // Save draft when text changes
    _messageController.addListener(_saveDraft);
  }
  
  @override
  void dispose() {
    _saveDraft();
    _typingTimer?.cancel();
    _messageController.removeListener(_onTyping);
    _messageController.removeListener(_saveDraft);
    _messageController.dispose();
    super.dispose();
  }
  
  void _onTyping() {
    if (_otherUserId == null) return;
    
    ChatService.setTyping(_otherUserId!, true);
    
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 2), () {
      ChatService.setTyping(_otherUserId!, false);
    });
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
            CircleAvatar(
              radius: 20,
              backgroundImage: _otherUser?.profileImageUrl != null || _otherUser?.photoUrls?.isNotEmpty == true
                  ? NetworkImage(_otherUser!.profileImageUrl ?? _otherUser!.photoUrls!.first)
                  : widget.match['image'] != null
                  ? NetworkImage(widget.match['image'])
                  : NetworkImage('https://picsum.photos/100/100?random=1'),
              backgroundColor: _otherUserId != null 
                  ? avatarColors[_otherUserId!.hashCode % avatarColors.length]
                  : Color(0xFF8B5CF6),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.match['name'] ?? widget.match['firstName'] ?? 'User',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                StreamBuilder<bool>(
                  stream: _otherUserId != null ? _getOnlineStatus(_otherUserId!) : Stream.value(false),
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data ?? false;
                    return Text(
                      isOnline ? 'Online' : 'Last seen recently',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    );
                  },
                ),
              ],
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
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearChatDialog();
                  break;
                case 'mute':
                  _toggleMute();
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
                    Icon(Icons.clear_all, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Text('Clear chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Text('Mute notifications'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Block user', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Report user', style: TextStyle(color: Colors.red)),
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
                // Typing indicator
                StreamBuilder<bool>(
                  stream: _otherUserId != null ? ChatService.getTypingStatus(_otherUserId!) : Stream.value(false),
                  builder: (context, snapshot) {
                    final isTyping = snapshot.data ?? false;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: isTyping ? 30 : 0,
                      child: isTyping ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text('${widget.match['name'] ?? widget.match['firstName'] ?? 'User'} is typing'),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ),
                      ) : null,
                    );
                  },
                ),
                // Messages
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _otherUserId != null ? ChatService.getMessages(_otherUserId!) : Stream.value([]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingSkeleton();
                      }
                      
                      final messages = snapshot.data ?? [];
                      
                      if (messages.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      final filteredMessages = _searchQuery.isEmpty 
                          ? messages 
                          : messages.where((msg) => 
                              msg.message.toLowerCase().contains(_searchQuery.toLowerCase())
                            ).toList();
                      
                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        reverse: true,
                        itemCount: filteredMessages.length,
                        itemBuilder: (context, index) {
                          final message = filteredMessages[index];
                          return _buildSwipeableMessage(message);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_replyingTo != null) _buildReplyPreview(),
          _buildMessageInput(),
        ],
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
      onLongPress: () => _showMessageOptions(message, isMe),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(maxWidth: (MediaQuery.of(context).size.width * 0.7).clamp(200.0, 280.0)),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 5),
                    bottomRight: Radius.circular(isMe ? 5 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
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
                        padding: EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 2,
                              height: 12,
                              color: isMe ? Colors.white.withOpacity(0.5) : AppTheme.primaryColor,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                message.replyToMessage!,
                                style: TextStyle(
                                  color: isMe ? Colors.white.withOpacity(0.6) : Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    message.messageType == 'location' 
                        ? _buildLocationMessage(message, isMe)
                        : message.messageType == 'gif'
                        ? _buildGifMessage(message, isMe)
                        : message.messageType == 'photo'
                        ? _buildPhotoMessage(message, isMe)
                        : Text(
                            message.message,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (isMe) ...[
                          SizedBox(width: 4),
                          Icon(
                            message.photoUrl == 'uploading' ? Icons.access_time :
                            message.status == 'read' ? Icons.done_all : 
                            message.status == 'delivered' ? Icons.done_all : Icons.done,
                            size: 16,
                            color: message.photoUrl == 'uploading' ? Colors.white70 :
                                   message.status == 'read' ? Colors.blue : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Reactions
              if (message.reactions.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 4),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: message.reactions.entries.map((entry) => 
                      Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text(entry.value, style: TextStyle(fontSize: 16)),
                      )
                    ).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showMessageOptions(ChatMessage message, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '😂', '😮', '😢', '😡', '👍'].map((emoji) => 
                GestureDetector(
                  onTap: () {
                    ChatService.addReaction(_otherUserId!, message.id, emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    child: Text(emoji, style: TextStyle(fontSize: 24)),
                  ),
                )
              ).toList(),
            ),
            Divider(),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _shareLocation,
            child: Icon(Icons.location_on, color: Colors.grey),
          ),
          SizedBox(width: 12),
          PopupMenuButton(
            icon: Icon(Icons.attach_file, color: Colors.grey),
            onSelected: (value) {
              if (value == 'camera') _pickPhoto(ImageSource.camera);
              if (value == 'gallery') _pickPhoto(ImageSource.gallery);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'camera', child: Row(children: [Icon(Icons.camera_alt), SizedBox(width: 8), Text('Camera')])),
              PopupMenuItem(value: 'gallery', child: Row(children: [Icon(Icons.photo), SizedBox(width: 8), Text('Gallery')])),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                if (_selectedPhoto != null)
                  Container(
                    margin: EdgeInsets.only(bottom: 8),
                    height: 60,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.file(_selectedPhoto!, width: 60, height: 60, fit: BoxFit.cover),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Photo selected',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20),
                          onPressed: () => setState(() { _selectedPhoto = null; _uploadedPhotoUrl = null; }),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: _selectedPhoto != null ? 'Add a caption...' : 'Type something to send...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: _showEmojiGifPicker,
            child: Icon(Icons.emoji_emotions, color: Colors.grey),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: _isUploading ? null : _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isUploading ? Colors.grey : AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: _isUploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
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
        setState(() {
          _otherUser = UserModel.fromMap(userDoc.data()!);
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
      final lastSeen = data['lastSeen'] as Timestamp?;
      if (lastSeen == null) return false;
      
      final now = DateTime.now();
      final lastSeenTime = lastSeen.toDate();
      return now.difference(lastSeenTime).inMinutes < 5;
    });
  }

  void _saveDraft() async {
    if (_otherUserId == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = ChatService.getChatId(currentUser.uid, _otherUserId!);
    final draft = _messageController.text.trim();
    
    if (draft.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'draft_${currentUser.uid}': draft,
      }, SetOptions(merge: true));
    } else {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'draft_${currentUser.uid}': FieldValue.delete(),
      });
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

  void _toggleMute() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chat notifications muted')),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report ${widget.match['name']}'),
        content: Text('Report inappropriate behavior or content.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _reportUser();
              Navigator.pop(context);
            },
            child: Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  void _reportUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.match['name']} has been reported')),
    );
  }

  void _shareLocation() async {
    if (_otherUserId == null) return;
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission permanently denied')),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Getting location...')),
      );
      
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
      
      await ChatService.sendMessage(
        receiverId: _otherUserId!,
        message: 'Shared location',
        messageType: 'location',
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildLocationMessage(ChatMessage message, bool isMe) {
    return GestureDetector(
      onTap: () => _openLocation(message.latitude!, message.longitude!),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isMe ? Colors.white : AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  message.locationName ?? 'Location',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Tap to open in maps',
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
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
      builder: (context) => DefaultTabController(
        length: 2,
        child: Container(
          height: 300,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Emojis'),
                  Tab(text: 'GIFs'),
                ],
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Emoji Tab
                    Container(
                      padding: EdgeInsets.all(16),
                      child: GridView.count(
                        crossAxisCount: 8,
                        children: [
                          '😀', '😂', '🥰', '😍', '🤔', '😎', '😴', '🤤',
                          '❤️', '💙', '💚', '💛', '🧡', '💜', '🖤', '🤍',
                          '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '👏',
                          '🔥', '💯', '✨', '⭐', '🌟', '💫', '🎉', '🎊',
                        ].map((emoji) => GestureDetector(
                          onTap: () {
                            _messageController.text += emoji;
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: EdgeInsets.all(4),
                            child: Text(emoji, style: TextStyle(fontSize: 24)),
                          ),
                        )).toList(),
                      ),
                    ),
                    // GIF Tab
                    Container(
                      padding: EdgeInsets.all(16),
                      child: GridView.count(
                        crossAxisCount: 2,
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
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                gifUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.gif, size: 50),
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
    // Always show local photo if available
    if (message.localPhotoPath != null) {
      return Container(
        constraints: BoxConstraints(maxWidth: 200, maxHeight: 200),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(message.localPhotoPath!),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            // Show spinner only during upload
            if (message.photoUrl == 'uploading')
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
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
      );
    }
    
    // Fallback to network image
    return Container(
      constraints: BoxConstraints(maxWidth: 200, maxHeight: 200),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          message.photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 200,
            height: 100,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.grey),
                Text('Photo not available', style: TextStyle(color: Colors.grey)),
              ],
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
}

