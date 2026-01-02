import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  // Hàm gửi thông báo
  static Future<void> sendNotification({
    required String receiverId, // ID người nhận
    required String title,
    required String message,
    String type = 'system', // system, like, approved...
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': receiverId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}