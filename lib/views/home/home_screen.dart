import 'package:cloud_firestore/cloud_firestore.dart'; // 1. Import Firestore
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/views/auth/login_screen.dart';
import 'package:my_app/views/profile/update_seller_screen.dart';
import 'package:my_app/views/vehicle/my_post_screen.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../vehicle/add_vehicle_screen.dart';
import '../widgets/vehicle_card.dart'; // 2. Import Widget thẻ xe


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Màu chủ đạo lấy theo ảnh mẫu (Tím xanh)
  final Color primaryColor = const Color(0xFF5D3FD3); 
  
  // Danh mục mẫu giống thiết kế
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.directions_car, 'label': 'Ô tô', 'color': Colors.blue},      // Có color
    {'icon': Icons.two_wheeler, 'label': 'Xe máy', 'color': Colors.purple},     // Có color
    {'icon': Icons.local_shipping, 'label': 'Xe tải', 'color': Colors.orange},  // Có color
    {'icon': Icons.electric_car, 'label': 'Xe điện', 'color': Colors.green},    // Có color
    {'icon': Icons.settings, 'label': 'Phụ tùng', 'color': Colors.grey},        // Có color
  ];

 @override
  Widget build(BuildContext context) {
    // Lấy theme màu chính
    final primaryColor = Theme.of(context).primaryColor;

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.user;
        // Kiểm tra quyền Seller
        final bool isSeller = user != null && (user.role == UserRole.seller || user.role == UserRole.admin);

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 1. APP BAR TÙY CHỈNH
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},

        ),
        title: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "XeGiáTốt",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        actions: [
          // Badge hiển thị Role (User/Seller)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  user?.role.name.toUpperCase() ?? "GUEST",
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {}, // TODO: Mở thông báo
          ),
        ],
      ),

      // 2. NỘI DUNG CHÍNH (Cuộn dọc)
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- A. BANNER GRADIENT ---
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D3FD3), Color(0xFFC51162)], // Tím sang Hồng
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Tìm xe mơ ước của bạn", 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Hàng ngàn xe mới & cũ chất lượng cao", 
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 10),
                ],
              ),
            ),

            // --- B. THANH TÌM KIẾM ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm xe...",
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 10),

            // --- C. ĐỊA ĐIỂM & BỘ LỌC ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.location_on_outlined, color: Colors.purple, size: 18),
                          SizedBox(width: 5),
                          Text("Hà Nội", style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.tune, color: Colors.white, size: 18),
                        SizedBox(width: 5),
                        Text("Lọc", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- D. DANH MỤC ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text("Danh mục", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 70,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _categories[index]['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(_categories[index]['icon'], color: _categories[index]['color']),
                        ),
                        const SizedBox(height: 8),
                        Text(_categories[index]['label'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- E. TIN MỚI NHẤT (GRID XE) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Mới nhất", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: (){}, 
                    child: Text("Xem tất cả", style: TextStyle(color: primaryColor)),
                  ),
                ],
              ),
            ),

            // --- LIST XE TỪ FIREBASE ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('status', isEqualTo: 'approved')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có tin đăng nào!"));
                }

                final docs = snapshot.data!.docs;

                // Dùng GridView nhưng tắt scroll (shrinkWrap) để cuộn chung với trang
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final vehicle = VehicleModel.fromMap(data, docs[index].id);

                    return VehicleCard(
                      vehicle: vehicle,
                      onTap: () {
                        // Navigate to detail
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80), // Khoảng trống đáy
          ],
        ),
      ),

      // 3. LOGIC NÚT ĐĂNG TIN (ĐÃ SỬA ĐỔI)
     floatingActionButton: isSeller
              ? SizedBox(
                  height: 65,
                  width: 65,
                  child: FloatingActionButton(
                    backgroundColor: Colors.purple,
                    elevation: 5,
                    shape: const CircleBorder(),
                    onPressed: () {
                      // Vì đã là Seller mới hiện nút này, nên không cần check lại quyền
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
                    },
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                )
              : null, // User thường không có nút này

          // 2. VỊ TRÍ FAB: Góc phải (endDocked)
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

// 3. THANH BOTTOM BAR
          bottomNavigationBar: BottomAppBar(
            elevation: 10,
            color: Colors.white,
            shape: null, // Không cần cắt khuyết nữa vì nút đã bay lên trên
            child: SizedBox(
              height: 60,
              child: Row(
                // Chia đều khoảng cách cho tất cả các nút
                mainAxisAlignment: MainAxisAlignment.spaceAround, 
                children: [
                  // --- ITEM 1: TRANG CHỦ (Chung) ---
                  _buildBottomItem(Icons.home, "Trang chủ", true, onTap: (){}),

                  // --- ITEM 2: TIN NHẮN (Chung) ---
                  _buildBottomItem(Icons.chat_bubble_outline, "Tin nhắn", false, onTap: (){}),

                  // --- ITEM 3: TIN CỦA TÔI (Chỉ dành cho SELLER) ---
                  if (isSeller)
                    _buildBottomItem(
                      Icons.assignment_outlined, 
                      "Tin của tôi", 
                      false, 
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPostsScreen()));
                      }
                    ),

                  // --- ITEM 4: YÊU THÍCH (Chung - Đã thêm lại cho Seller) ---
                  _buildBottomItem(
                    Icons.favorite_border, 
                    "Yêu thích", 
                    false, 
                    onTap: () { /* TODO: Mở màn hình yêu thích */ }
                  ),

                  // --- ITEM 5: TÀI KHOẢN (Chung) ---
                  _buildBottomItem(
                    Icons.person_outline, 
                    "Tài khoản", 
                    false, 
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

 

  // Cập nhật hàm _buildBottomItem để hỗ trợ InkWell (Bấm được)
  Widget _buildBottomItem(IconData icon, String label, bool isActive, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.purple : Colors.grey),
            Text(
              label, 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10, 
                color: isActive ? Colors.purple : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal
              )
            )
          ],
        ),
      ),
    );
  }
}