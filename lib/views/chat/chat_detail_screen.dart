import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/chat_provider.dart'; // Đảm bảo import đúng đường dẫn

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;
  final String receiverName;
  final String receiverId;
  final String vehicleTitle;
  final String vehicleId; // 1. Đã thêm tham số này để lưu vào DB
  final String? receiverAvatar;

  const ChatDetailScreen({
    super.key,
    required this.chatRoomId,
    required this.receiverName,
    required this.receiverId,
    required this.vehicleTitle,
    required this.vehicleId, // Bắt buộc phải có
    required this.receiverAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  // Hàm xử lý gửi tin nhắn
  void _handleSend() async {
    if (_msgController.text.trim().isEmpty) return; // 2. Sửa _messageController thành _msgController

    final String msg = _msgController.text.trim();
    _msgController.clear();

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Gọi provider để lưu tin nhắn và tạo phòng chat
    await chatProvider.sendMessage(
      chatRoomId: widget.chatRoomId,
      message: msg,
      senderId: currentUserId,
      receiverId: widget.receiverId,
      vehicleId: widget.vehicleId, 
      vehicleTitle: widget.vehicleTitle,
      receiverName: widget.receiverName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Hiển thị Avatar trên thanh tiêu đề
        leadingWidth: 40, // Thu nhỏ nút back
        title: Row(
          children: [
            // Hiển thị Avatar nhỏ
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
            // Hiển thị Tên và Tên xe
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
              colors: [
                Color(0xFF5D3FD3), // tím
                Color(0xFFC51162), // hồng đậm
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      
      ),
      body: Column(
        children: [
          // 1. DANH SÁCH TIN NHẮN
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms') // 3. Lưu ý: collection cha là chat_rooms (theo Provider cũ)
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // 4. Sửa createdAt thành timestamp
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Hãy bắt đầu cuộc trò chuyện!"));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUserId;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          msg['message'], // 5. Sửa msg['text'] thành msg['message']
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. Ô NHẬP TIN NHẮN
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController, // Sửa thành _msgController
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _handleSend, // 6. Gọi đúng tên hàm _handleSend
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