import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/vehicle/vehicle_detail_screen.dart';
import '../../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. SỬA LẠI SỐ LƯỢNG TAB TỪ 3 LÊN 4
    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Quản lý tin đăng"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          
          bottom: const TabBar(
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            isScrollable: false, // Cho phép cuộn nếu màn hình nhỏ
            tabs: [
              Tab(text: "Đang hiển thị"),
              Tab(text: "Chờ duyệt"),
              Tab(text: "Bị từ chối"),
              Tab(text: "Đã bán"), // 2. THÊM TAB MỚI
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab 1: Approved
            _VehicleListByStatus(status: 'approved'),
            
            // Tab 2: Pending
            _VehicleListByStatus(status: 'pending'),
            
            // Tab 3: Rejected
            _VehicleListByStatus(status: 'rejected'),

            // Tab 4: Sold (Đã bán) - 3. THÊM VIEW CHO TAB MỚI
            _VehicleListByStatus(status: 'sold'),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET CON ĐỂ HIỂN THỊ DANH SÁCH THEO TRẠNG THÁI ---
class _VehicleListByStatus extends StatelessWidget {
  final String status;

  const _VehicleListByStatus({required this.status});

  // 1. HÀM XỬ LÝ XÓA TIN (Giữ nguyên)
  void _confirmDelete(BuildContext context, String vehicleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa tin đăng?"),
        content: const Text("Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xóa không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('vehicles')
                    .doc(vehicleId)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã xóa tin đăng thành công!")),
                  );
                }
              } catch (e) {
                // Handle error
              }
            },
            child: const Text("Xóa ngay", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 4. HÀM XỬ LÝ ĐÁNH DẤU ĐÃ BÁN (MỚI THÊM)
  void _markAsSold(BuildContext context, String vehicleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận đã bán?"),
        content: const Text("Tin đăng sẽ được ẩn khỏi trang chủ và chuyển vào mục 'Đã bán'."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng dialog
              
              try {
                // Cập nhật trạng thái status -> 'sold'
                await FirebaseFirestore.instance
                    .collection('vehicles')
                    .doc(vehicleId)
                    .update({'status': 'sold'});

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chúc mừng! Đã cập nhật trạng thái thành công.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Xác nhận đã bán", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('ownerId', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          String msg = "";
          if (status == 'approved') msg = "Bạn không có xe nào đang bán.";
          else if (status == 'pending') msg = "Không có tin nào đang chờ duyệt.";
          else if (status == 'sold') msg = "Chưa có xe nào được bán.";
          else msg = "Không có tin nào bị từ chối.";
          return Center(child: Text(msg, style: const TextStyle(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            try {
              final vehicle = VehicleModel.fromMap(data, docId);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)
                  ]
                ),
                child: Column(
                  children: [
                    // Card Xe
                    SizedBox(
                      height: 280, 
                      child: VehicleCard(
                        vehicle: vehicle, 
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder : (_)=> VehicleDetailScreen(vehicle: vehicle)
                          ));
                        }
                      ),
                    ),
                    
                    // 5. THANH CÔNG CỤ (NÚT BẤM)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Canh phải
                        children: [
                          
                          // TRƯỜNG HỢP: XE ĐANG HIỂN THỊ -> HIỆN NÚT "ĐÃ BÁN"
                          if (status == 'approved') 
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextButton.icon(
                                onPressed: () => _markAsSold(context, docId),
                                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                label: const Text("Đã bán", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.green.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                ),
                              ),
                            ),

                          // Nút Xóa (Luôn hiện)
                          TextButton.icon(
                            onPressed: () => _confirmDelete(context, docId),
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            label: const Text("Xóa tin", style: TextStyle(color: Colors.red)),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } catch (e) {
              return const SizedBox();
            }
          },
        );
      },
    );
  }
}