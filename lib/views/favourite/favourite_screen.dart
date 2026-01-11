import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
import '../../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Yêu thích")),
        body: const Center(child: Text("Vui lòng đăng nhập để xem tin yêu thích")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tin đã lưu", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // 1. Lắng nghe danh sách yêu thích của User
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('addedAt', descending: true) // Tin mới lưu hiện lên đầu
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("Bạn chưa lưu tin nào!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final favoriteDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favoriteDocs.length,
            itemBuilder: (context, index) {
              final vehicleId = favoriteDocs[index]['vehicleId'];

              // 2. Với mỗi ID, tải thông tin chi tiết xe từ collection 'vehicles'
              // Dùng FutureBuilder vì ta cần lấy dữ liệu 1 lần cho mỗi item
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).get(),
                builder: (context, vehicleSnapshot) {
                  // 1. Đang tải
                  if (!vehicleSnapshot.hasData) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    );
                  }
                  
                  // 2. Nếu xe đã bị xóa vĩnh viễn
                  if (!vehicleSnapshot.data!.exists) {
                    return Container(
                       decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                       child: const Center(child: Text("Tin đã xóa", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    );
                  }

                  final data = vehicleSnapshot.data!.data() as Map<String, dynamic>;

                  // 🔥 3. (MỚI THÊM) KIỂM TRA TRẠNG THÁI XE
                  // Nếu xe chưa duyệt (pending) hoặc bị từ chối (rejected), không hiện lên
                  if (data['status'] != 'approved') {
                    return Container(
                       decoration: BoxDecoration(
                         color: Colors.grey[100], 
                         borderRadius: BorderRadius.circular(10),
                         border: Border.all(color: Colors.grey.shade300)
                       ),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(Icons.visibility_off_outlined, color: Colors.grey),
                           const SizedBox(height: 5),
                           const Text("Tin đang ẩn", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                           Text(
                             data['status'] == 'pending' ? "(Chờ duyệt)" : "(Đã ẩn/Từ chối)",
                             style: const TextStyle(fontSize: 10, color: Colors.grey),
                           ),
                         ],
                       ),
                    );
                  }
                  // ------------------------------------------

                  final vehicle = VehicleModel.fromMap(data, vehicleSnapshot.data!.id);

                  return VehicleCard(
                    vehicle: vehicle,
                    onTap: () {
                      Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_)=>VehicleDetailScreen(vehicle: vehicle),
                            ));
                      // TODO: Navigate to Detail
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}