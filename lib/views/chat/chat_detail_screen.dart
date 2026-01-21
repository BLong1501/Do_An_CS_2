import 'dart:io'; // Import for File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'package:my_app/views/profile/public_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/chat_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;
  final String receiverName;
  final String receiverId;
  final String vehicleTitle;
  final String vehicleId;
  final String? receiverAvatar;

  const ChatDetailScreen({
    super.key,
    required this.chatRoomId,
    required this.receiverName,
    required this.receiverId,
    required this.vehicleTitle,
    required this.vehicleId,
    required this.receiverAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isUploading = false; // To show loading state

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  // --- 1. Handle Send Text ---
  void _handleSend() async {
    if (_msgController.text.trim().isEmpty) return;

    final String msg = _msgController.text.trim();
    _msgController.clear();

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    await chatProvider.sendMessage(
      chatRoomId: widget.chatRoomId,
      message: msg,
      senderId: currentUserId,
      receiverId: widget.receiverId,
      vehicleId: widget.vehicleId,
      vehicleTitle: widget.vehicleTitle,
      receiverName: widget.receiverName,
      type: 'text', // Explicitly mark as text
    );
  }

  // --- 2. Handle Pick & Send Image ---
  void _handleSendImage() async {
    final ImagePicker picker = ImagePicker();
    // Pick image from gallery
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      try {
        await chatProvider.sendImageMessage(
          chatRoomId: widget.chatRoomId,
          imageFile: File(image.path),
          senderId: currentUserId,
          receiverId: widget.receiverId,
          vehicleId: widget.vehicleId,
          vehicleTitle: widget.vehicleTitle,
          receiverName: widget.receiverName,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending image: $e")),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.receiverAvatar != null && widget.receiverAvatar!.isNotEmpty
                  ? NetworkImage(widget.receiverAvatar!)
                  : null,
              child: widget.receiverAvatar == null || widget.receiverAvatar!.isEmpty
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName, style: const TextStyle(fontSize: 16)),
                  Text(
                    widget.vehicleTitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
    IconButton(
      icon: const Icon(Icons.bookmark_add_rounded), // Icon chữ 'i'
      tooltip: 'Xem hồ sơ',
      onPressed: () {
        // Chuyển sang màn hình hồ sơ công khai
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfileScreen(
              userId: widget.receiverId, // Truyền ID người đang chat cùng
            ),
          ),
        );
      },
    ),
  ],
      ),
      body: Column(
        children: [
          // Loading indicator when uploading image
          if (_isUploading)
            const LinearProgressIndicator(backgroundColor: Colors.transparent),

          // --- MESSAGE LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Start the conversation!"));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
  reverse: true,
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final msg = messages[index].data() as Map<String, dynamic>;
    final isMe = msg['senderId'] == currentUserId;
    
    // Lấy nội dung tin nhắn
    final String messageContent = msg['message'] ?? '';
    
    // 👇 LOGIC QUAN TRỌNG: Tự động phát hiện ảnh
    // 1. Kiểm tra trường 'type' từ DB
    // 2. HOẶC kiểm tra nếu nội dung bắt đầu bằng link ảnh của Firebase (để sửa lỗi hiện tại)
    final String type = msg['type'] ?? 'text';
    final bool isImage = type == 'image' || messageContent.startsWith('https://firebasestorage.googleapis.com');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isImage 
            ? Colors.transparent 
            : (isMe ? Colors.blue : Colors.grey[300]),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
        ),
      ),
        // 👇 Hiển thị Ảnh hoặc Chữ dựa trên biến isImage
        child: isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  messageContent, // Link ảnh
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 200, 
                      height: 200, 
                      child: Center(
                        child: CircularProgressIndicator(
                          color: isMe ? Colors.white : Colors.blue
                        )
                      )
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 50);
                  },
                ),
              )
            : Text(
                messageContent,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
      ),
    );
  },
);
              },
            ),
          ),

          // --- INPUT AREA ---
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                // 4. Button to pick Image
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: _handleSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: "Enter message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _handleSend,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}