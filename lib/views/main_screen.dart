import 'package:flutter/material.dart';
import 'package:my_app/views/chat/chat_list_screen.dart';
import 'package:my_app/views/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

// Import các màn hình con
import 'package:my_app/views/home/home_screen.dart';
// import 'package:my_app/views/chat/chat_list_screen.dart';
import 'package:my_app/views/vehicle/my_post_screen.dart';
import 'package:my_app/views/favourite/favourite_screen.dart';
// import 'package:my_app/views/profile/profile_screen.dart';
import 'package:my_app/views/vehicle/add_vehicle_screen.dart';
// import 'package:my_app/views/auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Tab hiện tại (Mặc định là 0 - Trang chủ)

  // Danh sách các màn hình tương ứng với từng tab
  final List<Widget> _pages = [
    const HomeScreen(),      // Index 0: Trang chủ
    const ChatListScreen(),  // Index 1: Tin nhắn
    const MyPostsScreen(),   // Index 2: Tin của tôi (Chỉ hiện cho Seller)
    const FavoriteScreen(),  // Index 3: Yêu thích
    const ProfileScreen(),   // Index 4: Tài khoản
  ];  

  @override
  void initState() {
    super.initState();
    // Gọi hàm tải thông tin user ngay khi màn hình MainScreen được tạo ra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchUserData();
    });
  }

  // --------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.user;
        
        // 👇 1. NẾU USER BỊ BAN -> HIỆN TRỰC TIẾP MÀN HÌNH ĐEN Ở ĐÂY 👇
        if (user != null && user.isBanned) {
          return Scaffold(
            backgroundColor: const Color(0xFF1E1E1E), // Nền đen
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, color: Colors.redAccent, size: 80),
                    const SizedBox(height: 30),
                    const Text(
                      "TÀI KHOẢN BỊ KHÓA",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Tài khoản của bạn đã bị khóa do vi phạm nghiêm trọng Tiêu chuẩn cộng đồng.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        // Nút Báo cáo
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.support_agent, color: Colors.white),
                            label: const Text("Báo cáo", style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Kháng cáo & Hỗ trợ"),
                                  content: const Text("Người phát triển: Trần Bảo Long\nSĐT: 0344907168\nEmail: tranbaolong5b@gmail.com\n\nVui lòng liên hệ để được xem xét."),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Nút Đăng xuất
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              await Provider.of<AuthProvider>(context, listen: false).logout();
                              // Nhớ import LoginScreen ở đầu file nhé
                              // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        // 👆 KẾT THÚC PHẦN MÀN HÌNH KHÓA 👆


        // ==========================================
        // 👇 LOGIC BÌNH THƯỜNG DÀNH CHO USER KHÔNG BỊ KHÓA 👇
        final bool isSeller = user != null && (user.role == UserRole.seller || user.role == UserRole.admin);
        
        if (!isSeller && _currentIndex == 2) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             setState(() {
               _currentIndex = 0;
             });
           });
        }
        
        final bool showFab = isSeller && _currentIndex == 0;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          floatingActionButton: showFab
              ? SizedBox(
                  height: 65, width: 65,
                  child: FloatingActionButton(
                    backgroundColor: Colors.purple,
                    elevation: 5,
                    shape: const CircleBorder(),
                    onPressed: () {
                      if (user?.canPost == false) {
                         _showRestrictionDialog(context, "Chức năng đăng bài đang bị tạm khóa do vi phạm tiêu chuẩn cộng đồng.");
                         return; 
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
                    },
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                )
              : null,

          bottomNavigationBar: BottomAppBar(
            elevation: 10,
            color: Colors.white,
            shape: null,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomItem(Icons.home, "Trang chủ", 0),
                  _buildBottomItem(Icons.chat_bubble_outline, "Tin nhắn", 1),
                  if (isSeller)
                    _buildBottomItem(Icons.assignment_outlined, "Tin của tôi", 2),
                  _buildBottomItem(Icons.favorite_border, "Yêu thích", 3),
                  _buildBottomItem(Icons.person_outline, "Tài khoản", 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomItem(IconData icon, String label, int index) { // Bỏ tham số isLogout
    final bool isActive = _currentIndex == index;
    
    return InkWell(
      onTap: () {
        // Chỉ đơn giản là chuyển tab
        setState(() {
          _currentIndex = index;
        });
      },
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
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.purple : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }
}
// Hàm hiển thị thông báo chặn
  void _showRestrictionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 10),
            Text("Hạn chế quyền", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đã hiểu"),
          ),
        ],
      ),
    );
  }