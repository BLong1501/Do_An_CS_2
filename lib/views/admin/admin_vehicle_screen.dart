import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../../services/notification_service.dart'; // Nhớ import service thông báo

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ADMIN DASHBOARD"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text("Không có tin nào cần duyệt"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              
              // 1. LẤY THÔNG TIN CẦN THIẾT ĐỂ GỬI THÔNG BÁO
              final ownerId = data['ownerId'] ?? '';
              final title = data['title'] ?? 'Xe chưa đặt tên';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text("${data['brand']} - ${data['price']} VNĐ"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút TỪ CHỐI
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        // 2. TRUYỀN THÔNG TIN VÀO HÀM TỪ CHỐI
                        onPressed: () => _rejectPost(context, docId, ownerId, title),
                      ),
                      const SizedBox(width: 8),
                      // Nút DUYỆT
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        // 3. TRUYỀN THÔNG TIN VÀO HÀM DUYỆT
                        onPressed: () => _updateStatus(
                          context, 
                          docId, 
                          'approved', 
                          ownerId: ownerId, 
                          vehicleTitle: title
                        ),
                        child: const Text("Duyệt", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- CÁC HÀM LOGIC ---

  // 4. CẬP NHẬT HÀM NHẬN THÊM ownerId VÀ vehicleTitle
  void _rejectPost(BuildContext context, String docId, String ownerId, String vehicleTitle) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Từ chối bài đăng"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Nhập lý do (VD: Ảnh mờ...)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // 5. GỌI HÀM UPDATE VỚI ĐẦY ĐỦ THAM SỐ
              _updateStatus(
                context, 
                docId, 
                'rejected', 
                reason: reasonController.text,
                ownerId: ownerId,          // Đã thêm
                vehicleTitle: vehicleTitle // Đã thêm
              );
              Navigator.pop(ctx);
            },
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // HÀM UPDATE VÀ GỬI THÔNG BÁO (Chuẩn như bạn đang làm)
  void _updateStatus(
    BuildContext context, 
    String docId, 
    String newStatus, 
    {String? reason, required String ownerId, required String vehicleTitle}
  ) {
    final updateData = <String, dynamic>{'status': newStatus};
    if (reason != null && reason.isNotEmpty) updateData['rejectionReason'] = reason;

    FirebaseFirestore.instance
        .collection('vehicles')
        .doc(docId)
        .update(updateData)
        .then((_) {
          
          // GỬI THÔNG BÁO
          String msgTitle = newStatus == 'approved' ? "Tin được duyệt" : "Tin bị từ chối";
          String msgContent = newStatus == 'approved' 
              ? "Chiếc xe $vehicleTitle của bạn đã được duyệt."
              : "Chiếc xe $vehicleTitle bị từ chối. Lý do: $reason";

          NotificationService.sendNotification(
            receiverId: ownerId,
            title: msgTitle,
            message: msgContent,
            type: newStatus == 'approved' ? 'success' : 'error',
          );

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã $newStatus")));
        })
        // ignore: invalid_return_type_for_catch_error
        .catchError((e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"))));
  }
}