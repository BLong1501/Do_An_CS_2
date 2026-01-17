import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/services/data_seeder.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/views/admin/tabs/admin_stats_screen.dart';
import 'package:my_app/views/admin/tabs/user_management_screen.dart';
import '../auth/login_screen.dart';

// Import các màn hình con
// import 'tabs/user_management_tab.dart'; // Tab Quản lý người dùng (Đã làm ở câu trước)
import 'package:my_app/views/admin/request_management_screen.dart'; // Tab Quản lý yêu cầu (Vừa tạo ở trên)
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0; // Tab mặc định là User Management

  // Danh sách các trang tương ứng với BottomBar
  final List<Widget> _pages = [
     UserManagementTab(),       // Tab 0: Người dùng
     RequestManagementScreen(), // Tab 1: Các đơn từ (Xe, Seller, Report)
     AdminStatsScreen(),        // Tab 2: Thống kê
    //  Center(child: Text("Màn hình Cấu Hình (Đang phát triển)")),
     Center(child: Text("Màn hình Cấu Hình (Đang phát triển)")), // Tab 3: Cấu hình
  ];

  // Tiêu đề tương ứng cho AppBar
  final List<String> _titles = [
    "Quản lý Người dùng",
    "Quản lý Yêu cầu & Duyệt",
    "Thống kê Báo cáo",
    "Cấu hình Hệ thống"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- 1. APP BAR (Giữ nguyên các nút chức năng) ---
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          // Nút thông báo
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: "Gửi thông báo hệ thống",
            onPressed: () => _showBroadcastDialog(context),
          ),
          // Nút Data Seeder
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: "Cập nhật dữ liệu mẫu",
            onPressed: () => _confirmSeedData(context),
          ),
          // Nút Đăng xuất
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Đăng xuất",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      // --- 2. BODY (Hiển thị theo index) ---
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // --- 3. BOTTOM NAVIGATION BAR (Thanh điều hướng dưới) ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed, // Quan trọng để hiện đủ 4 tab
        selectedItemColor: Colors.blueGrey[900],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Người dùng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in), // Icon checklist
            label: "Xét duyệt",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Thống kê",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Cấu hình",
          ),
        ],
      ),
    );
  }

  // --- CÁC HÀM PHỤ TRỢ (Giữ nguyên logic cũ của bạn) ---

  void _showBroadcastDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Gửi thông báo hệ thống"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Gửi đến TOÀN BỘ user.", style: TextStyle(color: Colors.red, fontSize: 12)),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tiêu đề")),
            TextField(controller: bodyController, decoration: const InputDecoration(labelText: "Nội dung")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              Navigator.pop(ctx);
              final adminId = FirebaseAuth.instance.currentUser!.uid;
              await NotificationService().sendNotification(
                receiverId: adminId, // Demo gửi cho admin trước
                title: "[HỆ THỐNG] ${titleController.text}",
                body: bodyController.text,
                type: "system"
              );
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi!")));
            },
            child: const Text("Gửi"),
          )
        ],
      ),
    );
  }

  void _confirmSeedData(BuildContext context) {
    // Logic DataSeeder cũ của bạn...
    // (Giữ nguyên code alert dialog ở đây)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Dữ liệu?"),
        content: const Text("Thêm dữ liệu mẫu vào Firestore."),
        actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
           ElevatedButton(
             onPressed: () async {
               Navigator.pop(ctx);
               await DataSeeder().seedData();
               if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Done!")));
             }, 
             child: const Text("Đồng ý")
           )
        ],
      ),
    );
  }
}