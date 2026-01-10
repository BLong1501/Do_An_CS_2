import 'package:flutter/material.dart';
import 'package:my_app/views/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/models/user_model.dart';
// import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

// Import các màn hình con
import 'package:my_app/views/home/home_screen.dart'; // Đổi tên HomeScreen cũ thành HomeContentScreen hoặc giữ nguyên nhưng sửa nội dung
// import 'package:my_app/views/chat/chat_list_screen.dart'; // Giả sử bạn có màn hình chat
import 'package:my_app/views/vehicle/my_post_screen.dart';
import 'package:my_app/views/favourite/favourite_screen.dart';
// import 'package:my_app/views/profile/profile_screen.dart'; // Màn hình tài khoản
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
  // Lưu ý: Sẽ xử lý logic hiển thị theo role ở hàm build
  final List<Widget> _pages = [
    const HomeScreen(),      // Index 0: Trang chủ (Sửa lại HomeScreen cũ bỏ BottomBar đi)
    const Center(child: Text("Tin nhắn")), // Index 1: Tin nhắn (Thay bằng ChatListScreen sau này)
    const MyPostsScreen(),   // Index 2: Tin của tôi (Chỉ hiện cho Seller)
    const FavoriteScreen(),  // Index 3: Yêu thích
    const ProfileScreen(), // Index 4: Tài khoản (Thay bằng ProfileScreen sau này)
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
        final bool isSeller = user != null && (user.role == UserRole.seller || user.role == UserRole.admin);

        return Scaffold(
          // Hiển thị nội dung trang theo index
          // Dùng IndexedStack để giữ trạng thái của các trang (không bị load lại khi chuyển tab)
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // NÚT ĐĂNG TIN (FAB)
          floatingActionButton: isSeller
              ? SizedBox(
                  height: 65, width: 65,
                  child: FloatingActionButton(
                    backgroundColor: Colors.purple,
                    elevation: 5,
                    shape: const CircleBorder(),
                    onPressed: () {
                      // Đăng tin vẫn là một hành động mở màn hình mới, nên dùng push
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
                    },
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

          // THANH BOTTOM BAR
          bottomNavigationBar: BottomAppBar(
            elevation: 10,
            color: Colors.white,
            shape: null,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 0. TRANG CHỦ
                  _buildBottomItem(Icons.home, "Trang chủ", 0),

                  // 1. TIN NHẮN
                  _buildBottomItem(Icons.chat_bubble_outline, "Tin nhắn", 1),

                  // 2. TIN CỦA TÔI (Chỉ Seller)
                  if (isSeller)
                    _buildBottomItem(Icons.assignment_outlined, "Tin của tôi", 2),

                  // 3. YÊU THÍCH
                  _buildBottomItem(Icons.favorite_border, "Yêu thích", 3),

                  // 4. TÀI KHOẢN
                  _buildBottomItem(Icons.person_outline, "Tài khoản", 4, isLogout: true), // Xử lý đặc biệt cho nút Logout tạm thời
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomItem(IconData icon, String label, int index, {bool isLogout = false}) {
    final bool isActive = _currentIndex == index;
    
    return InkWell(
      onTap: () async {
        if (isLogout) {
           // Tạm thời xử lý logout ở đây hoặc chuyển sang tab Tài khoản
           // Nếu muốn chuyển tab:
           setState(() => _currentIndex = index);
           
           // Nếu muốn logout luôn như cũ:
           /*
           await FirebaseAuth.instance.signOut();
           if (context.mounted) {
             Navigator.pushAndRemoveUntil(
               context,
               MaterialPageRoute(builder: (_) => const LoginScreen()),
               (route) => false,
             );
           }
           */
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
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