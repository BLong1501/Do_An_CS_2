import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/models/vehicle_model.dart';
import 'package:my_app/views/seller/edit_profile_screen.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
import 'package:my_app/views/widgets/vehicle_card.dart';
import 'package:my_app/views/vehicle/add_vehicle_screen.dart'; 

class MyStoreScreen extends StatelessWidget {
  const MyStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý Cửa hàng"),
      actions: [
        IconButton(
    icon: const Icon(Icons.edit),
    onPressed: () {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const EditStoreScreen()));
    },
  )
      ],),
      
      // 👇 SỬA 1: Thêm isStorePost: true để báo là đăng tin từ Shop
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const AddVehicleScreen(isStorePost: true))
          );
        },
        backgroundColor: Colors.purple,
        label: const Text("Đăng sản phẩm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('ownerId', isEqualTo: uid)
            .where('status', isEqualTo: 'approved') // Lấy tất cả xe của user này
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Bạn chưa đăng tin nào"));
          }

          // 👇 SỬA 2: Lọc thủ công để chỉ lấy những xe CÓ storeName (Xe của Shop)
          final allDocs = snapshot.data!.docs;
          final shopDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Chỉ lấy xe nào có trường storeName và không rỗng
            return data['storeName'] != null;
          }).toList();

          // Nếu lọc xong mà không có xe nào của shop
          if (shopDocs.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("Cửa hàng chưa có sản phẩm nào", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Text("Các bài đăng cá nhân sẽ không hiện ở đây.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }
          
          // Hiển thị danh sách đã lọc (shopDocs)
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: 2, 
               childAspectRatio: 0.65, // Tỷ lệ này giúp Card không bị lỗi overflow
               mainAxisSpacing: 10,
               crossAxisSpacing: 10
            ),
            itemCount: shopDocs.length, // Dùng shopDocs
            itemBuilder: (ctx, index) {
              final data = shopDocs[index].data() as Map<String, dynamic>;
              final vehicle = VehicleModel.fromMap(data, shopDocs[index].id);
              
              return VehicleCard(vehicle: vehicle, onTap: (){
                Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_)=>VehicleDetailScreen(vehicle: vehicle),
                            ));
              }); 
            },
          );
        },
      ),
    );
  }
}