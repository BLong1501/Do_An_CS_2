import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm tạo ID phòng chat (giữ nguyên như cũ)
  String getChatRoomId(String userId, String otherUserId, String vehicleId) {
    List<String> ids = [userId, otherUserId];
    ids.sort(); // Sắp xếp để ID luôn giống nhau dù ai là người bắt đầu
    return "${ids[0]}_${ids[1]}_$vehicleId";
  }

  // CẬP NHẬT HÀM GỬI TIN NHẮN QUAN TRỌNG NÀY
  Future<void> sendMessage({
    required String chatRoomId,
    required String message,
    required String senderId,
    required String receiverId,
    required String vehicleId, // Cần thêm cái này để biết đang chat về xe nào
    required String vehicleTitle, // Tiêu đề xe để hiển thị ở danh sách
    String? receiverName,
    String? receiverAvatar,
  }) async {
    final Timestamp timestamp = Timestamp.now();

    // 1. Tạo model tin nhắn
    Map<String, dynamic> messageData = {
      "senderId": senderId,
      "receiverId": receiverId,
      "message": message,
      "timestamp": timestamp,
      "isRead": false,
      "type": "text",
    };

    // 2. Lưu tin nhắn vào Sub-collection 'messages'
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // 3. QUAN TRỌNG: Cập nhật thông tin phòng chat (Để hiện trong ChatList)
    // Dùng set với SetOptions(merge: true) để nếu phòng chưa có thì tạo mới, có rồi thì cập nhật
    Map<String, dynamic> chatRoomData = {
      "chatRoomId": chatRoomId,
      "participants": [senderId, receiverId], // Mảng chứa ID 2 người để query
      "lastMessage": message,
      "lastTime": timestamp,
      "vehicleId": vehicleId,
      "vehicleTitle": vehicleTitle,
      // Lưu thêm info người nhận để hiển thị nhanh nếu cần (tùy chọn)
      "users": [senderId, receiverId] 
    };

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .set(chatRoomData, SetOptions(merge: true));
  }
}