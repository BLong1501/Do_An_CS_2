import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/notification_model.dart';
import 'package:my_app/models/vehicle_model.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final notifService = NotificationService();

    if (user == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có thông báo nào"));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // Convert dữ liệu sang Model
              final notification = NotificationModel.fromFirestore(docs[index]);

              return Container(
                color: notification.isRead ? Colors.white : Colors.blue[50],
                child: ListTile(
                  leading: _buildIcon(notification.type),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: columDetail(notification),
                  onTap: () {
                    // 1. Đánh dấu đã đọc
                    notifService.markAsRead(notification.id);

                    // 2. Xử lý sự kiện bấm (Mở màn hình tương ứng)
                    _handleNavigation(context, notification);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget columDetail(NotificationModel notif) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(notif.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 5),
        Text(
          DateFormat('HH:mm dd/MM/yyyy').format(notif.createdAt),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildIcon(String type) {
    switch (type) {
      case 'approved': return const Icon(Icons.check_circle, color: Colors.green);
      case 'rejected': return const Icon(Icons.cancel, color: Colors.orange);
      case 'account_banned': return const Icon(Icons.block, color: Colors.red);
      case 'new_post_following': return const Icon(Icons.rss_feed, color: Colors.blue);
      case 'violation_removed': return const Icon(Icons.gavel, color: Colors.red);
      default: return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  // Hàm xử lý khi ấn vào thông báo
  void _handleNavigation(BuildContext context, NotificationModel notif) async {
    
    // TRƯỜNG HỢP 1: Thông báo tin được duyệt (approved)
    // Hoặc thông báo Follower (new_post_following)
    if ((notif.type == 'approved' || notif.type == 'new_post_following') && notif.relatedId != null) {
      
      // 1. Hiển thị vòng quay loading để người dùng biết đang tải
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // 2. Lấy dữ liệu xe từ Firebase dựa trên relatedId
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(notif.relatedId)
            .get();

        // Tắt vòng quay loading
        if (context.mounted) Navigator.pop(context);

        if (doc.exists) {
          // 3. Chuyển đổi dữ liệu sang VehicleModel
          // (Đảm bảo bạn có hàm fromSnapshot hoặc fromMap trong VehicleModel)
          VehicleModel vehicle = VehicleModel.fromSnapshot(doc);

          // 4. Mở màn hình chi tiết
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VehicleDetailScreen(vehicle: vehicle),
              ),
            );
          }
        } else {
          // Trường hợp xe đã bị xóa sau khi duyệt
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Bài đăng này không còn tồn tại!")),
            );
          }
        }
      } catch (e) {
        // Tắt loading nếu lỗi
        if (context.mounted) Navigator.pop(context);
        print("Lỗi tải xe: $e");
      }
    } 
    
    // TRƯỜNG HỢP 2: Thông báo bị từ chối hoặc vi phạm
    else if (notif.type == 'rejected' || notif.type == 'violation_removed') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(notif.title),
          content: Text(notif.body), // Hiển thị lý do từ chối
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đã hiểu"),
            ),
            // Có thể thêm nút "Sửa lại bài" nếu muốn (Logic phức tạp hơn chút)
          ],
        ),
      );
    }
  }
}