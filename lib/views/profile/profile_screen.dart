import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_storage/firebase_storage.dart' ;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/views/profile/update_seller_screen.dart';
import 'package:my_app/views/seller/seller_info_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' ;
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false; // Biến trạng thái để hiện vòng xoay khi đang up ảnh

  // --- HÀM 1: CHỌN ẢNH VÀ UPLOAD ---
  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    // 1. Mở thư viện ảnh
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return; // Nếu user hủy chọn

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      File file = File(image.path);
      
      // 2. Upload lên Firebase Storage
      // Tạo đường dẫn: user_avatars/uid.jpg
      final ref = FirebaseStorage.instance.ref().child('user_avatars/${user.uid}.jpg');
      await ref.putFile(file);
      
      // 3. Lấy link ảnh về
      final String downloadUrl = await ref.getDownloadURL();

      // 4. Cập nhật Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      // 5. Cập nhật Provider để UI đổi ngay lập tức
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // --- HÀM 2: HIỆN HỘP THOẠI ĐỔI TÊN ---
  void _showEditNameDialog(BuildContext context, String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đổi tên hiển thị"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Tên mới"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              
              // Cập nhật tên
              try {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'displayName': nameController.text.trim()
                });
                // Load lại data
                if (context.mounted) {
                  Provider.of<AuthProvider>(context, listen: false).fetchUserData();
                }
              } catch (e) {
                // Xử lý lỗi
              }
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.user;

    if (userModel == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.black),
            onPressed: () => _showEditNameDialog(context, userModel.displayName),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // --- 1. AVATAR & TÊN ---
            Center(
              child: Column(
                children: [
                  // Stack để chồng icon máy ảnh lên avatar
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.purple.withOpacity(0.2), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: (userModel.photoUrl != null && userModel.photoUrl!.isNotEmpty)
                              ? NetworkImage(userModel.photoUrl!)
                              : null,
                          child: (userModel.photoUrl == null || userModel.photoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                      // Nút đổi ảnh
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _isUploading ? null : _pickAndUploadAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploading 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userModel.displayName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userModel.email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. THỐNG KÊ FOLLOW (Mới thêm) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Đang theo dõi", userModel.following),
                  Container(height: 30, width: 1, color: Colors.grey[300]), // Đường kẻ dọc
                  _buildStatItem("Người theo dõi", userModel.followers),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 5, color: Color(0xFFF5F5F5)), // Kẻ ngang phân cách lớn

            // --- 3. MENU CHỨC NĂNG ---
            _buildSectionTitle("Cài đặt & Tiện ích"),
            
            _buildMenuItem(
              icon: Icons.settings_outlined, 
              title: "Cài đặt tài khoản", 
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }
            ),
            
            _buildMenuItem(
              icon: userModel.role.name == 'seller' ? Icons.storefront : Icons.add_business,
              title: userModel.role.name == 'seller' ? 'Thông tin người bán':'Đăng ký bán hàng',
              onTap: (){
                if(userModel.role.name == 'seller'){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SellerInfoScreen()));

                  }else{
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UpgradeSellerScreen())
                    );

                  }
                }
              ),

            _buildMenuItem(
              icon: Icons.history, 
              title: "Lịch sử đăng nhập", 
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginHistoryScreen()));
              }
            ),

            _buildSectionTitle("Hỗ trợ"),

             _buildMenuItem(
              icon: Icons.feedback_outlined, 
              title: "Đóng góp ý kiến", 
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
              }
            ),
            
            _buildMenuItem(
              icon: Icons.help_outline, 
              title: "Trợ giúp & Hỗ trợ", 
              onTap: () {
                 // Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
              }
            ),

            const SizedBox(height: 10),
            
            // Nút Đăng xuất
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Provider.of<AuthProvider>(context, listen: false).logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("Đăng xuất", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị số liệu Follow
  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // Widget tiêu đề mục nhỏ
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500]),
        ),
      ),
    );
  }

  // Widget từng dòng menu
  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: Colors.purple, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}