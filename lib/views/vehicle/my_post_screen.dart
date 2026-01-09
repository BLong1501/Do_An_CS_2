import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng DefaultTabController để quản lý 3 tab
    return DefaultTabController(
      length: 3, // Tổng số tab
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Quản lý tin đăng"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          // 1. THANH TAB BAR Ở TRÊN CÙNG
          bottom: const TabBar(
            labelColor: Colors.purple, // Màu chữ khi chọn
            unselectedLabelColor: Colors.grey, // Màu chữ khi không chọn
            indicatorColor: Colors.purple, // Thanh gạch chân
            tabs: [
              Tab(text: "Đang hiển thị"),
              Tab(text: "Chờ duyệt"),
              Tab(text: "Bị từ chối"),
            ],
          ),
        ),
        // 2. NỘI DUNG TƯƠNG ỨNG VỚI CÁC TAB
        body: const TabBarView(
          children: [
            // Tab 1: Approved
            _VehicleListByStatus(status: 'approved'),
            
            // Tab 2: Pending
            _VehicleListByStatus(status: 'pending'),
            
            // Tab 3: Rejected
            _VehicleListByStatus(status: 'rejected'),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET CON ĐỂ HIỂN THỊ DANH SÁCH THEO TRẠNG THÁI ---
class _VehicleListByStatus extends StatelessWidget {
  final String status; // Nhận vào trạng thái muốn lọc (approved/pending/rejected)

  const _VehicleListByStatus({required this.status});
  // 1. HÀM XỬ LÝ XÓA TIN
  void _confirmDelete(BuildContext context, String vehicleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa tin đăng?"),
        content: const Text("Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xóa không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Đóng hộp thoại
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Đóng hộp thoại trước
              
              try {
                // Xóa document trong Firestore
                await FirebaseFirestore.instance
                    .collection('vehicles')
                    .doc(vehicleId)
                    .delete();

                // (Tùy chọn) Nếu bạn muốn xóa cả ảnh trong Storage thì cần viết thêm logic ở đây
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã xóa tin đăng thành công!")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi khi xóa: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Xóa ngay", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
          else msg = "Không có tin nào bị từ chối.";
          return Center(child: Text(msg, style: const TextStyle(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id; // Lấy ID để xóa

            try {
              final vehicle = VehicleModel.fromMap(data, docId);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 15), // Khoảng cách giữa các xe
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
                          // TODO: Xem chi tiết hoặc Sửa tin
                        }
                      ),
                    ),
                    
                    // 2. THANH CÔNG CỤ (NÚT XÓA)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Hiển thị trạng thái/Lý do từ chối
                          Expanded(
                            child: status == 'rejected'
                                ? const Text(
                                    "Vi phạm chính sách",
                                    style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic, fontSize: 12),
                                  )
                                : Text(
                                    status == 'approved' ? "Đang hiển thị" : "Đang chờ duyệt",
                                    style: TextStyle(
                                      color: status == 'approved' ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12
                                    ),
                                  ),
                          ),

                          // Nút Xóa
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
