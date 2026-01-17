import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm tạo ID phòng chat
  String getChatRoomId(String userId, String otherUserId, String vehicleId) {
    List<String> ids = [userId, otherUserId];
    ids.sort(); 
    return "${ids[0]}_${ids[1]}_$vehicleId";
  }

  // --- HÀM GỬI TIN NHẮN (ĐÃ SỬA LẠI TÊN TRƯỜNG) ---
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

    // 1. Lưu tin nhắn vào Sub-collection (Giữ nguyên)
    Map<String, dynamic> messageData = {
      "senderId": senderId,
      "receiverId": receiverId,
      "message": message,
      "timestamp": timestamp,
      "isRead": false,
      "type": "text",
    };

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // 2. Cập nhật thông tin phòng chat (QUAN TRỌNG: PHẢI SỬA Ở ĐÂY)
    Map<String, dynamic> chatRoomData = {
      "chatRoomId": chatRoomId,
      
      // ✅ SỬA 1: Đổi thành 'participants' để khớp với ChatListScreen
      "participants": [senderId, receiverId], 
      
      // (Lưu thêm 'users' để dự phòng nếu sau này cần dùng, không thừa)
      "users": [senderId, receiverId], 

      "lastMessage": message,
      
      // ✅ SỬA 2: Đổi thành 'lastTime' để khớp với .orderBy('lastTime') bên UI
      "lastTime": timestamp, 
      
      "vehicleId": vehicleId,
      "vehicleTitle": vehicleTitle,
    };

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .set(chatRoomData, SetOptions(merge: true));
  }
}