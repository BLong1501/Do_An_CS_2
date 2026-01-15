import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/admin/tabs/admin_user_detail_screen.dart'; // Import màn hình chi tiết

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. THANH TÌM KIẾM (Giữ nguyên ở trên cùng)
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Tìm theo tên hoặc email...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchText = value.toLowerCase();
              });
            },
          ),
        ),

        // 2. THANH TAB BAR
        TabBar(
          controller: _tabController,
          labelColor: Colors.blueGrey[900],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueGrey,
          tabs: const [
            Tab(text: "Người dùng (Seller/User)"),
            Tab(text: "Quản trị viên (Admin)"),
          ],
        ),

        // 3. NỘI DUNG TAB (Sử dụng hàm build list tái sử dụng)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Chỉ hiện User và Seller
              _buildUserList(filterRoles: ['user', 'seller']),
              
              // Tab 2: Chỉ hiện Admin
              _buildUserList(filterRoles: ['admin']),
            ],
          ),
        ),
      ],
    );
  }

  // --- HÀM XÂY DỰNG DANH SÁCH (Tái sử dụng cho cả 2 tab) ---
  Widget _buildUserList({required List<String> filterRoles}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Không có dữ liệu."));
        }

        // LỌC DỮ LIỆU:
        // 1. Lọc theo Role (Tab)
        // 2. Lọc theo Search Text
        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final String role = data['role'] ?? "user";
          final String email = (data['email'] ?? "").toString().toLowerCase();
          final String name = (data['displayName'] ?? "").toString().toLowerCase();

          // Điều kiện 1: Phải thuộc nhóm Role của Tab hiện tại
          bool roleMatch = filterRoles.contains(role);
          
          // Điều kiện 2: Phải khớp từ khóa tìm kiếm
          bool searchMatch = email.contains(_searchText) || name.contains(_searchText);

          return roleMatch && searchMatch;
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text("Không tìm thấy kết quả phù hợp."));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final userId = userDoc.id;

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserDetailScreen(userId: userId),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  backgroundColor: Colors.blueGrey,
                  child: photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (role == 'seller')
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                    if (role == 'admin')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("ADMIN", style: TextStyle(color: Colors.white, fontSize: 8)),
                      ),
                    if (isBanned)
                      Container(
                        margin: const EdgeInsets.only(left: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("BANNED", style: TextStyle(color: Colors.white, fontSize: 8)),
                      ),
                  ],
                ),
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