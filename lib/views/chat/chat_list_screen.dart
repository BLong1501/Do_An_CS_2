import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // 👇 Nhớ import thư viện này
import 'package:intl/intl.dart';
import 'package:my_app/views/chat/chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // --- HÀM 1: Đánh dấu tất cả tin nhắn trong phòng là "Đã đọc" ---
  Future<void> _markAsRead(String chatRoomId) async {
    try {
      // Tìm tất cả tin nhắn chưa đọc mà người nhận là mình
      final unreadDocs = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('receiverId', isEqualTo: currentUserId)
          .get();

      // Dùng WriteBatch để update hàng loạt (nhanh và tiết kiệm request)
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      
      print("Đã đánh dấu đã đọc cho phòng: $chatRoomId");
    } catch (e) {
      print("Lỗi markAsRead: $e");
    }
  }

  // --- HÀM 2: Xóa cuộc trò chuyện ---
  Future<void> _deleteChatRoom(String chatRoomId) async {
    // Show Dialog xác nhận trước khi xóa
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa cuộc trò chuyện này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false; // Nếu bấm ngoài hoặc back thì mặc định là false

    if (confirm) {
      await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa cuộc trò chuyện")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tin nhắn",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Chưa có tin nhắn nào", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: chatDocs.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final chatRoomDoc = chatDocs[index];
              final data = chatRoomDoc.data() as Map<String, dynamic>;
              final String chatRoomId = chatRoomDoc.id;

              // Lấy thông tin cơ bản
              final String lastMessage = data['lastMessage'] ?? "";
              final Timestamp? timestamp = data['lastTime'];
              final String timeString = timestamp != null
                  ? DateFormat('HH:mm dd/MM').format(timestamp.toDate())
                  : "";
              final String vehicleTitle = data['vehicleTitle'] ?? "Tin xe";
              final String vehicleId = data['vehicleId'] ?? "";
              final List<dynamic> participants = data['participants'];
              
              // Tìm ID người chat cùng
              final String otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => "Unknown",
              );

              // 👇 WIDGET TRƯỢT (SLIDABLE)
              return Slidable(
                key: Key(chatRoomId),
                // Vuốt từ phải sang trái (End Action Pane)
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    // Nút 1: Đánh dấu đã đọc
                    SlidableAction(
                      onPressed: (context) {
                        _markAsRead(chatRoomId); // Gọi hàm đánh dấu đọc
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.mark_chat_read,
                      label: 'Đã đọc',
                    ),
                    // Nút 2: Xóa
                    SlidableAction(
                      onPressed: (context) {
                        _deleteChatRoom(chatRoomId); // Gọi hàm xóa
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Xóa',
                    ),
                  ],
                ),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    String displayName = "Người dùng";
                    String? avatarUrl;

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      displayName = userData['displayName'] ?? userData['storeName'] ?? "Người dùng";
                      avatarUrl = userData['photoUrl'] ?? userData['storeAva'];
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blue[100],
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? const Icon(Icons.person, color: Colors.blue) : null,
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "[$vehicleTitle]",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12, color: Colors.blueGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(timeString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          
                          // 👇 STREAM BUILDER ĐỂ HIỂN THỊ SỐ TIN NHẮN CHƯA ĐỌC
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('chat_rooms')
                                .doc(chatRoomId)
                                .collection('messages')
                                .where('isRead', isEqualTo: false) // Chỉ lấy tin chưa đọc
                                .where('receiverId', isEqualTo: currentUserId) // Gửi cho mình
                                .snapshots(),
                            builder: (context, msgSnapshot) {
                              if (!msgSnapshot.hasData || msgSnapshot.data!.docs.isEmpty) {
                                return const SizedBox.shrink(); // Không có tin chưa đọc thì ẩn
                              }

                              final int count = msgSnapshot.data!.docs.length;
                              final String countText = count > 10 ? "10+" : "$count";

                              return Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  countText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // 👇 QUAN TRỌNG: Khi ấn vào thì gọi hàm đánh dấu đã đọc ngay
                        _markAsRead(chatRoomId);

                        // Chuyển sang màn hình chat
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatRoomId: chatRoomId,
                              receiverId: otherUserId,
                              receiverName: displayName,
                              vehicleTitle: vehicleTitle,
                              vehicleId: vehicleId,
                              receiverAvatar: avatarUrl,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}