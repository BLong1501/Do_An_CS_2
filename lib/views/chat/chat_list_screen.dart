  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:my_app/views/chat/chat_detail_screen.dart';

  class ChatListScreen extends StatefulWidget {
    const ChatListScreen({super.key});

    @override
    State<ChatListScreen> createState() => _ChatListScreenState();
  }

  class _ChatListScreenState extends State<ChatListScreen> {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Tin nhắn",
            style: TextStyle(color: Color.fromARGB(255, 255, 254, 254), fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
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
        // 1. Lắng nghe dữ liệu từ collection 'chat_rooms'
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chat_rooms')
              // Điều kiện: Lấy các phòng chat mà mảng 'participants' có chứa ID của mình
              .where('participants', arrayContains: currentUserId)
              .orderBy('lastTime', descending: true) // Sắp xếp tin mới nhất lên đầu
              .snapshots(),
          builder: (context, snapshot) {
            // Trạng thái đang tải
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Trạng thái lỗi hoặc không có dữ liệu
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

            return ListView.builder(
              itemCount: chatDocs.length,
              itemBuilder: (context, index) {
                final data = chatDocs[index].data() as Map<String, dynamic>;
                
                // Xử lý dữ liệu để hiển thị
                final String lastMessage = data['lastMessage'] ?? "";
                final Timestamp? timestamp = data['lastTime'];
                final String timeString = timestamp != null 
                    ? DateFormat('HH:mm dd/MM').format(timestamp.toDate()) 
                    : "";
                
                // Lấy thông tin xe
                final String vehicleTitle = data['vehicleTitle'] ?? "Tin xe";
                final String vehicleId = data['vehicleId'] ?? "";

                // Xác định ID người kia (để biết mình đang chat với ai)
                final List<dynamic> participants = data['participants'];
                final String otherUserId = participants.firstWhere(
                  (id) => id != currentUserId, 
                  orElse: () => "Unknown",
                );

                // 2. Vì trong chat_rooms chỉ lưu ID, ta cần lấy tên người kia
                // Cách đơn giản nhất: Hiển thị tên xe làm tiêu đề chính
                // Cách nâng cao: Dùng FutureBuilder để fetch tên user từ collection 'users' (sẽ làm ở dưới)
                
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    String displayName = "Người dùng";
                    String? avatarUrl;

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      displayName = userData['displayName'] ?? userData['storeName'] ?? "Người dùng";
                      avatarUrl = userData['photoUrl'] ?? userData['storeAva'];
                    }

                    return Column(
                      children: [
                        ListTile(
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
                              // Hiện tên xe màu đậm hơn chút để dễ phân biệt
                              Text(
                                "[$vehicleTitle]", 
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.blueGrey),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
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
                          trailing: Text(timeString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          
                          // 3. Sự kiện khi bấm vào dòng chat -> Mở lại ChatDetailScreen
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  chatRoomId: chatDocs[index].id,
                                  receiverId: otherUserId,
                                  receiverName: displayName,
                                  vehicleTitle: vehicleTitle,
                                  vehicleId: vehicleId,
                                  receiverAvatar: avatarUrl, // Truyền avatar vào để ChatDetail hiển thị
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 80),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      );
    }
  }