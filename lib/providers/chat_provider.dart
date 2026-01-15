import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm tạo ID phòng chat (Giữ nguyên)
  String getChatRoomId(String userId, String otherUserId, String vehicleId) {
    List<String> ids = [userId, otherUserId];
    ids.sort(); 
    return "${ids[0]}_${ids[1]}_$vehicleId";
  }

  // CẬP NHẬT HÀM GỬI TIN NHẮN
  Future<void> sendMessage({
    required String chatRoomId,
    required String message,
    required String senderId,
    required String receiverId,
    required String vehicleId,
    required String vehicleTitle,
    String? receiverName,
    String? receiverAvatar,
  }) async {
    final Timestamp timestamp = Timestamp.now();

    // 1. Tạo model tin nhắn
    Map<String, dynamic> messageData = {
      "senderId": senderId,
      "receiverId": receiverId,
      "message": message,
      "timestamp": timestamp, // Dùng cho bong bóng chat
      "isRead": false,
      "type": "text",
    };

    // 2. Lưu tin nhắn vào Sub-collection
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // 3. Cập nhật thông tin phòng chat
    Map<String, dynamic> chatRoomData = {
      "chatRoomId": chatRoomId,
      
      // 👇 QUAN TRỌNG: Query bên UI đang dùng field 'users' này
      "users": [senderId, receiverId], 
      
      "lastMessage": message,
      
      // 👇 SỬA Ở ĐÂY: Đổi 'lastTime' thành 'lastMessageTime' để khớp với UI
      "lastMessageTime": timestamp, 
      
      "vehicleId": vehicleId,
      "vehicleTitle": vehicleTitle,
    };

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .set(chatRoomData, SetOptions(merge: true));
  }
}