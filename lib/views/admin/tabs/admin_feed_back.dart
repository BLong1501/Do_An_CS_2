import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminFeedbackScreen extends StatelessWidget {
  const AdminFeedbackScreen({super.key});

  // Hàm hiển thị chi tiết và đánh dấu là đã đọc
  void _showFeedbackDetail(BuildContext context, String docId, Map<String, dynamic> data) {
    // Nếu chưa đọc (isRead = false) thì cập nhật thành true
    if (data['isRead'] == false) {
      FirebaseFirestore.instance.collection('feedbacks').doc(docId).update({'isRead': true});
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(
              data['type'] == 'Báo lỗi (Bug)' ? Icons.bug_report : Icons.lightbulb,
              color: data['type'] == 'Báo lỗi (Bug)' ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(data['type'] ?? "Ý kiến", style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Người gửi: ${data['userName']} (${data['role']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Email: ${data['userEmail']}", style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      "Thời gian: ${data['createdAt'] != null ? DateFormat('dd/MM/yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate()) : '---'}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text("Nội dung chi tiết:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(data['content'] ?? "Không có nội dung", style: const TextStyle(fontSize: 15, height: 1.4)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('feedbacks').doc(docId).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa ý kiến đóng góp")));
              }
            },
            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
            label: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Ý kiến người dùng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lấy danh sách feedback, xếp mới nhất lên đầu
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Chưa có ý kiến đóng góp nào.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final feedbacks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final doc = feedbacks[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final bool isRead = data['isRead'] ?? false;
              String timeAgo = "Vừa xong";
              if (data['createdAt'] != null) {
                timeAgo = DateFormat('dd/MM HH:mm').format((data['createdAt'] as Timestamp).toDate());
              }

              // Cài đặt icon và màu sắc theo loại ý kiến
              Color iconColor = Colors.blue;
              IconData iconData = Icons.feedback;
              
              if (data['type'] == 'Báo lỗi (Bug)') {
                iconColor = Colors.red;
                iconData = Icons.bug_report;
              } else if (data['type'] == 'Góp ý tính năng') {
                iconColor = Colors.orange;
                iconData = Icons.lightbulb;
              } else if (data['type'] == 'Tố cáo người dùng khác') {
                iconColor = Colors.deepPurple;
                iconData = Icons.gavel;
              }

              return Card(
                elevation: isRead ? 1 : 3, // Thẻ chưa đọc sẽ nổi bật hơn
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  // Thêm viền màu xanh nếu chưa đọc
                  side: isRead ? BorderSide.none : BorderSide(color: Colors.blue.withOpacity(0.5), width: 1.5),
                ),
                color: isRead ? Colors.white : Colors.blue[50], 
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.15),
                    child: Icon(iconData, color: iconColor),
                  ),
                  title: Text(
                    data['type'] ?? "Khác",
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      color: isRead ? Colors.black87 : Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        data['content'] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['userName'] ?? 'Ẩn danh', style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                          Text(timeAgo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  trailing: isRead 
                      ? null 
                      : Container(
                          width: 12, height: 12,
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        ), // Chấm xanh báo hiệu tin mới
                  onTap: () => _showFeedbackDetail(context, doc.id, data),
                ),
              );
            },
          );
        },
      ),
    );
  }
}