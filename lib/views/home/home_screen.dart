import 'package:cloud_firestore/cloud_firestore.dart'; // 1. Import Firestore
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:my_app/views/auth/login_screen.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../vehicle/add_vehicle_screen.dart';
import '../widgets/vehicle_card.dart'; // 2. Import Widget thẻ xe

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin User để hiển thị câu chào (nếu thích)
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền nhẹ cho đẹp
      appBar: AppBar(
        title: const Text('Chợ Tốt Phương Tiện'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 1. Gọi hàm đăng xuất từ Firebase
              await FirebaseAuth.instance.signOut();

              // 2. Gọi thêm hàm logout của Provider (nếu có) để xóa data User trong RAM
              // (Nếu AuthProvider của bạn có hàm logout thì bỏ comment dòng dưới)
              // context.read<AuthProvider>().logout();

              // 3. Điều hướng thủ công về trang Login (Xóa sạch lịch sử cũ)
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // Xóa hết các trang trước đó
                );
              }
            },
          ),
        ],
      ),

      // --- PHẦN THAY ĐỔI CHÍNH Ở ĐÂY ---
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dòng chào hỏi (Tùy chọn)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chào, ${user?.displayName ?? "Khách"}!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Nút Admin Seeder cũ (Ẩn đi nếu không phải Admin)
                if (user?.role.name == 'admin')
                  const Text(
                    "Admin Mode",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // 2. Danh sách xe từ Firebase
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .where(
                    'status',
                    isEqualTo: 'approved',
                  ) // 👈 QUAN TRỌNG: Chỉ hiện xe đã duyệt
                  .orderBy('createdAt', descending: true) // Mới nhất lên đầu
                  .snapshots(),
              builder: (context, snapshot) {
                // Đang tải...
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Không có dữ liệu
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Chưa có tin đăng nào!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // Có dữ liệu -> Hiển thị dạng lưới (2 cột)
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 cột
                    childAspectRatio: 0.75, // Tỷ lệ khung hình
                    crossAxisSpacing: 10, // Khoảng cách ngang
                    mainAxisSpacing: 10, // Khoảng cách dọc
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    // Convert data
                    final data = docs[index].data() as Map<String, dynamic>;
                    final vehicle = VehicleModel.fromMap(data, docs[index].id);

                    // Hiển thị Thẻ xe
                    return VehicleCard(
                      vehicle: vehicle,
                      onTap: () {
                        // TODO: Bước tiếp theo sẽ làm màn hình chi tiết
                        print("Bấm vào xe: ${vehicle.title}");
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Nút Đăng tin (Giữ nguyên)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
        ),
        label: const Text('Đăng tin', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
