import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  // 1. Tạo ID phòng chat duy nhất (nguoiMua_nguoiBan_maXe)
  String getChatRoomId(String buyerId, String sellerId, String vehicleId) {
    // Luôn sắp xếp ID người dùng để A chat với B giống B chat với A
    // Nhưng ở đây ta gắn theo xe, nên ID phòng nên là:
    return "${buyerId}_${sellerId}_$vehicleId";
  }

  // 2. Gửi tin nhắn
  Future<void> sendMessage(String chatRoomId, String messageText, String senderId, String receiverId, String vehicleTitle) async {
    if (messageText.trim().isEmpty) return;

    final timestamp = FieldValue.serverTimestamp();

    // A. Lưu tin nhắn vào sub-collection 'messages'
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': messageText,
      'createdAt': timestamp,
    });

    // B. Cập nhật thông tin tóm tắt ở collection 'chats' (để hiện ở danh sách tin nhắn)
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'users': [senderId, receiverId], // Danh sách người tham gia
      'lastMessage': messageText,
      'lastTime': timestamp,
      'chatRoomId': chatRoomId,
      'vehicleTitle': vehicleTitle, // Lưu tên xe để biết đang chat về xe gì
    }, SetOptions(merge: true)); // merge: true để không ghi đè nếu đã có
  }
}