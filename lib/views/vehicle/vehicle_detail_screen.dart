import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/profile/public_profile_screen.dart';
import '../../models/vehicle_model.dart';

class VehicleDetailScreen extends StatelessWidget {
  final VehicleModel vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    // Xác định tên người bán/shop
    
    final bool isStore = vehicle.storeName != null;

    return Scaffold(
      backgroundColor: Colors.white,
      // Nút Back đè lên ảnh hoặc AppBar thường
      appBar: AppBar(
        title: Text(vehicle.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SLIDE ẢNH SẢN PHẨM
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
                          child: Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey)),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. GIÁ VÀ TÊN XE
                  Text(
                    _formatCurrency(vehicle.price),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${vehicle.location} • ${_getTimeAgo(vehicle.createdAt)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  // 3. THÔNG SỐ KỸ THUẬT (CHIA 2 CỘT)
                  const Text("Thông số kỹ thuật",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  // GridView để chia 2 cột
                  GridView.count(
                    crossAxisCount: 2, // 2 cột
                    shrinkWrap: true, // Để nằm gọn trong SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Không cuộn riêng
                    childAspectRatio: 4, // Tỉ lệ chiều rộng/cao của mỗi ô (chỉnh số này để ô dẹt hay cao)
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
                  const Text("Mô tả chi tiết",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    vehicle.description.isNotEmpty
                        ? vehicle.description
                        : "Không có mô tả.",
                    style: const TextStyle(height: 1.5, fontSize: 14),
                  ),

                  const Divider(height: 30),

                  // 5. THÔNG TIN NGƯỜI ĐĂNG (Dùng FutureBuilder để lấy Avatar mới nhất)
                  // ... inside VehicleDetailScreen.dart

                  // 5. THÔNG TIN NGƯỜI ĐĂNG
                 // 5. THÔNG TIN NGƯỜI ĐĂNG
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(vehicle.ownerId)
                        .get(),
                    builder: (context, snapshot) {
                      // 1. Khởi tạo giá trị mặc định
                      String sellerName = vehicle.storeName ?? "Đang tải...";
                      String? displayAvaUrl;
                      
                      // 2. Nếu đã tải xong dữ liệu từ Firestore
                      if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        
                        if (isStore) {
                           // --- LOGIC CỬA HÀNG ---
                           displayAvaUrl = userData['storeAva'];
                           if (userData['storeName'] != null) {
                             sellerName = userData['storeName'];
                           }
                        } else {
                           // --- LOGIC CÁ NHÂN (SỬA Ở ĐÂY) ---
                           displayAvaUrl = userData['photoUrl'];
                           // 👇 Lấy tên hiển thị thật (displayName), nếu lỗi thì mới hiện "Người dùng"
                           sellerName = userData['displayName'] ?? "Người dùng";
                        }
                      }

                      // 3. Giao diện hiển thị
                      return GestureDetector(
                        onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PublicProfileScreen(userId: vehicle.ownerId),
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
                              // Avatar
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: isStore ? Colors.purple[100] : Colors.blue[100],
                                backgroundImage: displayAvaUrl != null 
                                    ? NetworkImage(displayAvaUrl) 
                                    : null,
                                child: displayAvaUrl == null 
                                    ? Icon(
                                        isStore ? Icons.store : Icons.person,
                                        color: isStore ? Colors.purple : Colors.blue,
                                        size: 30,
                                      )
                                    : null,
                              ),
                              
                              const SizedBox(width: 15),
                              
                              // Thông tin Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 👇 HIỂN THỊ TÊN NGƯỜI BÁN / TÊN SHOP
                                    Text(
                                      sellerName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // 👇 LOGIC HIỂN THỊ BADGE HOẶC CHÚ THÍCH
                                    if (isStore)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple,
                                          borderRadius: BorderRadius.circular(4)
                                        ),
                                        child: const Text("Cửa hàng uy tín", style: TextStyle(color: Colors.white, fontSize: 10)),
                                      )
                                    else
                                      // 👇 HIỆN DÒNG BẠN MUỐN: "Người bán cá nhân"
                                      const Text(
                                        "Người bán cá nhân", 
                                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)
                                      ), 
                                  ],
                                ),
                              ),
                              
                              // Nút Gọi
                               IconButton(
                                onPressed: () { /* Logic gọi */ },
                                icon: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  radius: 18,
                                  child: Icon(Icons.phone, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30), // Khoảng trống dưới cùng
                ],
              ),
            ),
          ],
        ),
      ),
      // Nút liên hệ dưới đáy (Tùy chọn)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,-2))]
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          onPressed: () { /* Logic chat hoặc gọi */ },
          child: const Text("LIÊN HỆ NGAY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  // Widget con hiển thị 1 dòng thông số
  Widget _buildSpecItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trên
      children: [
        // Nhãn (Màu xám)
        Expanded(
          flex: 4,
          child: Text(
            "$label:", 
            style: const TextStyle(color: Colors.grey, fontSize: 13)
          ),
        ),
        // Giá trị (Màu đen)
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

  // Format tiền
  String _formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  // Format thời gian
  String _getTimeAgo(DateTime createdDate) {
    final duration = DateTime.now().difference(createdDate);
    if (duration.inDays > 7) return DateFormat('dd/MM/yyyy').format(createdDate);
    if (duration.inDays >= 1) return "${duration.inDays} ngày trước";
    if (duration.inHours >= 1) return "${duration.inHours} giờ trước";
    return "Vừa xong";
  }
}

// tôi muốn làm thêm cái khi ấn vào nơi thông tin về ngườ bán ở vehicle_detail_screen sẽ hiện ra trang thông tin các nhân của người bán hoặc cửa hàng và có cả nút follow khi ấn vào nút follow thì người follow sẽ hiện trong danh sách người follow ở trang store_followers_screen đối với cửa hàng và tran