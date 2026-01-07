import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tin đăng của tôi"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lọc xe theo ownerId là user hiện tại
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('ownerId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Bạn chưa đăng tin nào!"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final vehicle = VehicleModel.fromMap(data, docs[index].id);
              
              // Hiển thị Card xe kèm trạng thái (Duyệt/Chờ/Từ chối)
              return Column(
                children: [
                  // --- SỬA Ở ĐÂY: BỌC TRONG SIZEDBOX ---
                  SizedBox(
                    height: 280, // Bắt buộc phải có chiều cao cố định
                    child: VehicleCard(vehicle: vehicle, onTap: () {}),
                  ),
                  // -------------------------------------

                  // Hiển thị trạng thái nhỏ bên dưới
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 5), // Thêm chút padding top cho đẹp
                    child: Row(
                      children: [
                        const Text("Trạng thái: ", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          vehicle.status == 'approved' ? "Đang hiển thị" 
                          : vehicle.status == 'pending' ? "Đang chờ duyệt" 
                          : "Bị từ chối",
                          style: TextStyle(
                            color: vehicle.status == 'approved' ? Colors.green 
                            : vehicle.status == 'pending' ? Colors.orange 
                            : Colors.red
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}