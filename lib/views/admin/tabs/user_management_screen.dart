import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/admin/tabs/admin_user_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- 1. HÀM TẠO USER (ĐÃ BỔ SUNG SĐT VÀ ĐỊA CHỈ) ---
  Future<void> _createNewUser({
    required String email, 
    required String password, 
    required String name, 
    required String role,
    required String phone,   
    required String address, 
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    FirebaseApp? tempApp;
    try {
      // Tạo App phụ để không bị logout admin hiện tại
      tempApp = await Firebase.initializeApp(name: 'TempApp', options: Firebase.app().options);

      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      // Lưu Full thông tin vào Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': name,
        'phoneNumber': phone,    // <-- Lưu SĐT
        'address': address,      // <-- Lưu Địa chỉ
        'photoUrl': null,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isBanned': false,
        'canPost': true,
        'followers': 0,
        'following': 0,
        // Nếu là seller thì thêm các trường mặc định của seller
        if (role == 'seller') ...{
           'storeName': name, // Mặc định tên shop giống tên người
           'storeFollowers': 0,
           'isSellerVerified': true, // Admin tạo thì cho duyệt luôn hoặc false tùy bạn
        }
      });

      await tempApp.delete();
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        Navigator.pop(context); // Tắt dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã tạo $role: $email thành công!")));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (tempApp != null) await tempApp.delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // --- 2. HỘP THOẠI THÔNG MINH (XỬ LÝ LOGIC TAB) ---
  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();   // <-- Mới
    final addressController = TextEditingController(); // <-- Mới
    
    // Kiểm tra xem đang ở Tab nào?
    // index 0: Người dùng (User/Seller)
    // index 1: Quản trị viên (Admin)
    final bool isAdminTab = _tabController.index == 1;

    // Nếu ở Tab Admin thì mặc định role là admin, ngược lại mặc định là user
    String selectedRole = isAdminTab ? 'admin' : 'user';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isAdminTab ? "Thêm Quản trị viên" : "Thêm Người dùng mới"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email (*)")),
                  TextField(controller: passController, decoration: const InputDecoration(labelText: "Mật khẩu (*)"), obscureText: true),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên hiển thị (*)")),
                  TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Số điện thoại")), // <-- Nhập SĐT
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: "Địa chỉ")), // <-- Nhập Địa chỉ
                  const SizedBox(height: 15),
                  
                  // LOGIC HIỂN THỊ CHỌN ROLE
                  if (isAdminTab) ...[
                    // Nếu là Tab Admin: Chỉ hiện text thông báo, không cho chọn
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                      child: const Text("Vai trò: QUẢN TRỊ VIÊN (ADMIN)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    )
                  ] else ...[
                    // Nếu là Tab User: Cho chọn User hoặc Seller
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: "Vai trò", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text("Người mua (User)")),
                        DropdownMenuItem(value: 'seller', child: Text("Người bán (Seller)")),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedRole = val!);
                      },
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
              ElevatedButton(
                onPressed: () {
                  if (emailController.text.isEmpty || passController.text.isEmpty || nameController.text.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ Email, Mật khẩu, Tên")));
                     return;
                  }
                  
                  _createNewUser(
                    email: emailController.text.trim(),
                    password: passController.text.trim(),
                    name: nameController.text.trim(),
                    role: selectedRole,
                    phone: phoneController.text.trim(),     // <-- Truyền vào hàm
                    address: addressController.text.trim(), // <-- Truyền vào hàm
                  );
                },
                child: const Text("Tạo ngay"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm theo tên hoặc email...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
            ),
          ),

          // 2. TAB BAR
          TabBar(
            controller: _tabController,
            labelColor: Colors.blueGrey[900],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueGrey,
            onTap: (index) {
              // Gọi setState để cập nhật lại nút FloatingActionButton khi đổi tab (tùy chọn, nhưng tốt cho UI)
              setState(() {});
            },
            tabs: const [
              Tab(text: "Người dùng (Seller/User)"),
              Tab(text: "Quản trị viên (Admin)"),
            ],
          ),

          // 3. DANH SÁCH
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(filterRoles: ['user', 'seller']),
                _buildUserList(filterRoles: ['admin']),
              ],
            ),
          ),
        ],
      ),
      
      // NÚT TẠO MỚI (Màu sắc thay đổi theo Tab để dễ nhận biết)
      floatingActionButton: FloatingActionButton(
        backgroundColor: _tabController.index == 1 ? Colors.red[900] : Colors.blueGrey[900],
        onPressed: _showAddUserDialog,
        child: Icon(
          _tabController.index == 1 ? Icons.admin_panel_settings : Icons.person_add, 
          color: Colors.white
        ),
      ),
    );
  }

  // ... (Hàm _buildUserList GIỮ NGUYÊN như cũ) ...
  Widget _buildUserList({required List<String> filterRoles}) {
    // (Copy y nguyên hàm _buildUserList từ câu trả lời trước vào đây)
     return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Không có dữ liệu."));

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final String role = data['role'] ?? "user";
          final String email = (data['email'] ?? "").toString().toLowerCase();
          final String name = (data['displayName'] ?? "").toString().toLowerCase();
          bool roleMatch = filterRoles.contains(role);
          bool searchMatch = email.contains(_searchText) || name.contains(_searchText);
          return roleMatch && searchMatch;
        }).toList();

        if (users.isEmpty) return const Center(child: Text("Không tìm thấy kết quả."));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 10), // Padding bottom để không bị nút FAB che
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final userId = userDoc.id;
            // ... lấy data ...
            final String email = userData['email'] ?? "No Email";
            final String name = userData['displayName'] ?? "No Name";
            final String? photoUrl = userData['photoUrl'];
            final String role = userData['role'] ?? "user";
            final bool isBanned = userData['isBanned'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isBanned ? Colors.grey[200] : Colors.white,
              child: ListTile(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: userId)));
                },
                leading: CircleAvatar(
                 backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
      ? NetworkImage(photoUrl) 
      : null,
                  backgroundColor: Colors.blueGrey,
                  child: (photoUrl == null || photoUrl.isEmpty) 
      ? const Icon(Icons.person, color: Colors.white) 
      : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                subtitle: Text(email),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}