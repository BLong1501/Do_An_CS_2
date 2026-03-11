import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:my_app/models/vehicle_model.dart';
import 'package:my_app/views/seller/edit_profile_screen.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
import 'package:my_app/views/widgets/vehicle_card.dart';
import 'package:my_app/views/vehicle/add_vehicle_screen.dart'; 
import 'package:my_app/views/seller/store_followers_screen.dart';

class MyStoreScreen extends StatelessWidget {
  const MyStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.user;
    final uid = userModel?.uid;

    if (uid == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Cửa hàng"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const EditStoreScreen()));
            },
          )
        ],
      ),
      
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

      body: Column(
        children: [
          // --- 1. PHẦN HIỂN THỊ FOLLOWER (ĐÃ SỬA REAL-TIME) ---
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              // Lấy số lượng follow, nếu chưa load xong thì lấy tạm từ Provider
              int currentFollowers = userModel?.storeFollowers ?? 0;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                currentFollowers = data['storeFollowers'] ?? 0;
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.purple.withOpacity(0.05),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => StoreFollowersScreen(storeId: uid))
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            "$currentFollowers", // Số liệu cập nhật ngay lập tức
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Người theo dõi cửa hàng",
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
                    ],
                  ),
                ),
              );
            }
          ),
          
          const Divider(height: 1),

          // --- 2. DANH SÁCH XE ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('ownerId', isEqualTo: uid)
                  .where('status', isEqualTo: 'approved')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Bạn chưa đăng tin nào"));
                }

                // 👇 Lọc thủ công xe của Shop chuẩn xác 100% giống Profile
                final allDocs = snapshot.data!.docs;
                final shopDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['storeName'] != null && data['storeName'].toString().trim().isNotEmpty;
                }).toList();

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
                
                return GridView.builder(
                  // 👇 THÊM PADDING BOTTOM 80 ĐỂ KHÔNG BỊ NÚT NỔI CHE KHUẤT
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                     crossAxisCount: 2, 
                     childAspectRatio: 0.65, 
                     mainAxisSpacing: 10,
                     crossAxisSpacing: 10
                  ),
                  itemCount: shopDocs.length,
                  itemBuilder: (ctx, index) {
                    final data = shopDocs[index].data() as Map<String, dynamic>;
                    final vehicle = VehicleModel.fromMap(data, shopDocs[index].id);
                    
                    return VehicleCard(
                      vehicle: vehicle, 
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_)=>VehicleDetailScreen(vehicle: vehicle),
                          )
                        );
                      }
                    ); 
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}