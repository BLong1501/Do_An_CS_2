import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart'; // Để dùng UserRole enum

class SellerApprovalTab extends StatelessWidget {
  const SellerApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Lấy danh sách yêu cầu đang chờ
      stream: FirebaseFirestore.instance
          .collection('seller_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Không có yêu cầu nâng cấp nào"));

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final reqId = requests[index].id;
            final userId = data['uid'];

            return Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Shop: ${data['storeName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Họ tên: ${data['fullName']}"),
                    Text("CCCD: ${data['citizenId']}"),
                    const SizedBox(height: 10),
                    // Hiển thị 2 ảnh CCCD
                    Row(
                      children: [
                        Expanded(child: Image.network(data['frontIdUrl'], height: 100, fit: BoxFit.cover)),
                        const SizedBox(width: 10),
                        Expanded(child: Image.network(data['backIdUrl'], height: 100, fit: BoxFit.cover)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text("Từ chối", style: TextStyle(color: Colors.white)),
                          onPressed: () => _rejectRequest(reqId, userId),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text("Duyệt Seller", style: TextStyle(color: Colors.white)),
                          onPressed: () => _approveRequest(reqId, userId),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // LOGIC DUYỆT (Quan trọng)
  Future<void> _approveRequest(String reqId, String userId) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Cập nhật bảng requests thành 'approved'
    batch.update(
      FirebaseFirestore.instance.collection('seller_requests').doc(reqId), 
      {'status': 'approved'}
    );

    // 2. Cập nhật bảng users: role -> seller và isPendingUpgrade -> false
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(userId), 
      {
        'role': 'seller', // Lưu ý: Đảm bảo string này khớp với cách bạn convert Enum
        'isPendingUpgrade': false
      }
    );

    await batch.commit();
  }

  // Logic Từ chối
  Future<void> _rejectRequest(String reqId, String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('seller_requests').doc(reqId), {'status': 'rejected'});
    batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {'isPendingUpgrade': false});
    await batch.commit();
  }
}