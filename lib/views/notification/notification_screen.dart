import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import thư viện format ngày tháng (cần cài intl trong pubspec.yaml nếu muốn đẹp)
// import 'package:intl/intl.dart'; 

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Vui lòng đăng nhập"));

    return Scaffold(
      appBar: AppBar(title: const Text("Thông báo")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid) // Chỉ lấy thông báo của mình
            .orderBy('createdAt', descending: true) // Mới nhất lên đầu
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) return const Center(child: Text("Bạn chưa có thông báo nào"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // Check màu sắc dựa trên loại thông báo
              Color iconColor = Colors.blue;
              IconData icon = Icons.notifications;
              
              if (data['type'] == 'error') {
                iconColor = Colors.red;
                icon = Icons.error;
              } else if (data['type'] == 'success') {
                iconColor = Colors.green;
                icon = Icons.check_circle;
              }

              return Card(
                color: data['isRead'] ? Colors.white : Colors.blue[50], // Chưa đọc thì màu xanh nhạt
                child: ListTile(
                  leading: Icon(icon, color: iconColor),
                  title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['message'] ?? ''),
                  onTap: () {
                    // Đánh dấu đã đọc khi bấm vào
                    FirebaseFirestore.instance.collection('notifications').doc(docs[index].id).update({'isRead': true});
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