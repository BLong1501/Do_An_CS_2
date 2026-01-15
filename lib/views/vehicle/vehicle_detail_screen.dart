import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/providers/chat_provider.dart';
import 'package:my_app/views/chat/chat_detail_screen.dart';
import 'package:my_app/views/profile/public_profile_screen.dart';
import 'package:my_app/views/vehicle/add_vehicle_screen.dart';
import 'package:my_app/views/admin/report/report_dialog_screen.dart'; // Import Dialog báo cáo
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';

class VehicleDetailScreen extends StatelessWidget {
  final VehicleModel vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    // Xác định xem đây là bài đăng của Cửa hàng hay Cá nhân
    final bool isStorePost =
        vehicle.storeName != null && vehicle.storeName!.isNotEmpty;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Kiểm tra xem người xem có phải là chủ xe không
    final bool isOwner = 
        currentUserId != null && currentUserId == vehicle.ownerId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(vehicle.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        // Các nút hành động trên AppBar
        actions: isOwner
            ? [
                // Nút Sửa (Chỉ hiện cho chủ xe)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: "Chỉnh sửa",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddVehicleScreen(
                          isStorePost: isStorePost,
                          vehicleToEdit: vehicle,
                        ),
                      ),
                    ).then((_) {
                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                ),
                // Nút Xóa (Chỉ hiện cho chủ xe)
                IconButton(
                  icon: const Icon(Icons.delete, color: Color.fromARGB(255, 188, 67, 67)),
                  tooltip: "Xóa tin",
                  onPressed: () {
                    _confirmDelete(context);
                  },
                ),
              ]
            : [
                // Nút Báo cáo (Chỉ hiện cho người xem)
                IconButton(
                  icon: const Icon(Icons.report_gmailerrorred, color: Colors.red),
                  tooltip: "Báo cáo vi phạm",
                  onPressed: () {
                    if (currentUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Vui lòng đăng nhập để báo cáo.")));
                      return;
                    }
                    
                    showDialog(
                      context: context,
                      builder: (ctx) => ReportDialog(
                        vehicleId: vehicle.id,
                        reportedUserId: vehicle.ownerId,
                        vehicleTitle: vehicle.title,
                      ),
                    );
                  },
                ),
            ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE SLIDER
            SizedBox(
              height: 250,
              child: vehicle.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: vehicle.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          vehicle.images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. GIÁ & TIÊU ĐỀ
                  Text(
                    _formatCurrency(vehicle.price),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${vehicle.location} • ${_getTimeAgo(vehicle.createdAt)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  // 3. THÔNG SỐ KỸ THUẬT
                  const Text(
                    "Thông số kỹ thuật",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 4,
                    children: [
                      _buildSpecItem("Hãng xe", vehicle.brand),
                      _buildSpecItem("Năm sx", vehicle.year.toString()),
                      _buildSpecItem("Tình trạng", vehicle.condition),
                      _buildSpecItem("Nhiên liệu", vehicle.fuelType),
                      _buildSpecItem("Xuất xứ", vehicle.origin),
                      _buildSpecItem("Dung tích", vehicle.capacity),
                      _buildSpecItem("Trọng lượng", "${vehicle.weight} kg"),
                      _buildSpecItem("Màu sắc", vehicle.color),
                      _buildSpecItem("Odo", "${vehicle.mileage} km"),
                    ],
                  ),

                  const Divider(height: 30),

                  // 4. MÔ TẢ CHI TIẾT
                  const Text(
                    "Mô tả chi tiết",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vehicle.description.isNotEmpty
                        ? vehicle.description
                        : "Không có mô tả.",
                    style: const TextStyle(height: 1.5, fontSize: 14),
                  ),

                  const Divider(height: 30),

                  // 5. THÔNG TIN NGƯỜI BÁN
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(vehicle.ownerId)
                        .get(),
                    builder: (context, snapshot) {
                      String sellerName = "Đang tải...";
                      String? displayAvaUrl;

                      // Fallback name
                      if (isStorePost && vehicle.storeName != null) {
                        sellerName = vehicle.storeName!;
                      }

                      if (snapshot.hasData &&
                          snapshot.data != null &&
                          snapshot.data!.exists) {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;

                        if (isStorePost) {
                          // Logic hiển thị Shop
                          displayAvaUrl = userData['storeAva'];
                          if (userData['storeName'] != null) {
                            sellerName = userData['storeName'];
                          }
                        } else {
                          // Logic hiển thị Cá nhân
                          displayAvaUrl = userData['photoUrl'];
                          sellerName = userData['displayName'] ?? "Người dùng";
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(
                                userId: vehicle.ownerId,
                                forceIndividual: !isStorePost,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: isStorePost
                                    ? Colors.purple[100]
                                    : Colors.blue[100],
                                backgroundImage: displayAvaUrl != null
                                    ? NetworkImage(displayAvaUrl)
                                    : null,
                                child: displayAvaUrl == null
                                    ? Icon(
                                        isStorePost
                                            ? Icons.store
                                            : Icons.person,
                                        color: isStorePost
                                            ? Colors.purple
                                            : Colors.blue,
                                        size: 30,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sellerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (isStorePost)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          "Cửa hàng uy tín",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      )
                                    else
                                      const Text(
                                        "Người bán cá nhân",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const CircleAvatar(
                                backgroundColor: Colors.green,
                                radius: 18,
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // BOTTOM NAVIGATION BAR: NÚT LIÊN HỆ
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () { 
             // 1. Kiểm tra đăng nhập
             if (currentUserId == null) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập để chat!")));
               return;
             }
             
             // 2. Không cho tự chat với chính mình
             if (isOwner) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đây là bài đăng của bạn!")));
               return;
             }

             // 3. Tạo ID phòng chat
             final chatProvider = Provider.of<ChatProvider>(context, listen: false);
             final chatRoomId = chatProvider.getChatRoomId(currentUserId, vehicle.ownerId, vehicle.id);

             // 4. Lấy tên người bán
             String sellerDisplayName = "Người bán";
             if (vehicle.storeName != null && vehicle.storeName!.isNotEmpty) {
               sellerDisplayName = vehicle.storeName!;
             }

             // 5. Chuyển sang màn hình Chat
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (_) => ChatDetailScreen(
                   chatRoomId: chatRoomId,
                   receiverId: vehicle.ownerId,
                   receiverName: sellerDisplayName,
                   vehicleId: vehicle.id,     
                   vehicleTitle: vehicle.title,
                   receiverAvatar: null, 
                 ),
               ),
             );
          },
          child: const Text(
            "LIÊN HỆ NGAY",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // --- CÁC HÀM PHỤ TRỢ (HELPER METHODS) ---

  Widget _buildSpecItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            "$label:",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value.isEmpty ? "---" : value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  String _getTimeAgo(DateTime createdDate) {
    final duration = DateTime.now().difference(createdDate);
    if (duration.inDays > 7)
      return DateFormat('dd/MM/yyyy').format(createdDate);
    if (duration.inDays >= 1) return "${duration.inDays} ngày trước";
    if (duration.inHours >= 1) return "${duration.inHours} giờ trước";
    return "Vừa xong";
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text(
          "Bạn có chắc chắn muốn xóa bài đăng này không? Hành động này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                await FirebaseFirestore.instance
                    .collection('vehicles')
                    .doc(vehicle.id)
                    .delete();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã xóa bài đăng thành công")),
                  );
                  Navigator.pop(context); // Quay về màn hình trước
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi xóa: $e")));
                }
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}