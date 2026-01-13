import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart'; 
import '../vehicle/vehicle_detail_screen.dart'; 

class PublicProfileScreen extends StatefulWidget {
  final String userId; 
  final bool forceIndividual;

  const PublicProfileScreen({super.key, required this.userId, this.forceIndividual = false});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isFollowing = false;
  bool _isLoading = true;
  UserModel? _sellerUser;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // 👇 Biến này để hiển thị số lượng follow thay đổi ngay lập tức trên UI
  int _localFollowerCount = 0; 

  @override
  void initState() {
    super.initState();
    _fetchSellerInfo();
    _checkIfFollowing();
  }

  // 1. Lấy thông tin người bán
  Future<void> _fetchSellerInfo() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // 👇 LOGIC QUAN TRỌNG: Xác định chế độ hiển thị (Shop hay Cá nhân)
        bool isStoreMode = false;
        
        if (widget.forceIndividual) {
           isStoreMode = false; // Bị ép -> Cá nhân
        } else {
           // Tự động: Nếu có role seller hoặc có tên shop -> Shop
           isStoreMode = user.role == UserRole.seller || (user.storeName != null && user.storeName!.isNotEmpty);
        }
        
        setState(() {
          _sellerUser = user;
          // Lấy đúng số follower dựa trên chế độ
          _localFollowerCount = isStoreMode ? user.storeFollowers : user.followers;
        });
      }
    } catch (e) {
      print("Lỗi lấy thông tin: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Kiểm tra trạng thái Follow
  Future<void> _checkIfFollowing() async {
    if (_currentUserId.isEmpty) return;
    
    // Kiểm tra trong collection 'following' của người đang đăng nhập
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(_currentUserId)
        .collection('following').doc(widget.userId).get();
        
    if (mounted) {
      setState(() => _isFollowing = doc.exists);
    }
  }

  // 3. 👇 HÀM FOLLOW / UNFOLLOW (LOGIC CHÍNH)
  Future<void> _toggleFollow() async {
    if (_currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập!")));
      return;
    }
    if (_currentUserId == widget.userId) return; // Không tự follow mình

    // A. Xác định xem đối phương là Shop hay Cá nhân
    bool isStoreTarget = false;
    if (widget.forceIndividual) {
      isStoreTarget = false;
    } else {
      isStoreTarget = _sellerUser!.role == UserRole.seller || (_sellerUser!.storeName != null && _sellerUser!.storeName!.isNotEmpty);
    }
    
    // B. Lưu trạng thái cũ để backup nếu lỗi
    final bool originalState = _isFollowing;
    final int originalCount = _localFollowerCount;

    // C. CẬP NHẬT UI NGAY LẬP TỨC (Optimistic Update)
    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _localFollowerCount += 1; // Đã theo dõi -> Cộng 1
      } else {
        _localFollowerCount -= 1; // Bỏ theo dõi -> Trừ 1
      }
    });

    try {
      // D. THỰC HIỆN GHI VÀO FIREBASE (Dùng Batch để đảm bảo an toàn dữ liệu)
      final batch = FirebaseFirestore.instance.batch();
      
      final myUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);
      final targetUserRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      // 1. Reference đến danh sách 'following' của MÌNH
      final myFollowingRef = myUserRef.collection('following').doc(widget.userId);
      
      // 2. Reference đến danh sách 'followers' của ĐỐI PHƯƠNG
      // Nếu đối phương là Shop -> lưu vào 'store_followers', cá nhân -> 'followers'
      final targetFollowerRef = targetUserRef.collection(isStoreTarget ? 'store_followers' : 'followers').doc(_currentUserId);

      if (!originalState) {
        // --- TRƯỜNG HỢP: FOLLOW (Chưa follow -> Ấn follow) ---
        
        // Tạo document trong sub-collection
        batch.set(myFollowingRef, {'createdAt': FieldValue.serverTimestamp()});
        batch.set(targetFollowerRef, {'createdAt': FieldValue.serverTimestamp()});

        // Tăng biến đếm
        batch.update(myUserRef, {'following': FieldValue.increment(1)});
        batch.update(targetUserRef, {
          isStoreTarget ? 'storeFollowers' : 'followers': FieldValue.increment(1)
        });

      } else {
        // --- TRƯỜNG HỢP: UNFOLLOW (Đang follow -> Ấn bỏ) ---
        
        // Xóa document
        batch.delete(myFollowingRef);
        batch.delete(targetFollowerRef);

        // Giảm biến đếm
        batch.update(myUserRef, {'following': FieldValue.increment(-1)});
        batch.update(targetUserRef, {
          isStoreTarget ? 'storeFollowers' : 'followers': FieldValue.increment(-1)
        });
      }

      // Thực thi lệnh
      await batch.commit();

    } catch (e) {
      // Nếu lỗi mạng hoặc server, hoàn tác lại UI cũ
      print("Lỗi follow: $e");
      if (mounted) {
        setState(() {
          _isFollowing = originalState;
          _localFollowerCount = originalCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối, vui lòng thử lại!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    // Nếu không tìm thấy user hoặc user bị null
    if (_sellerUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lỗi"), backgroundColor: Colors.white, foregroundColor: Colors.black,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF5D3FD3), // tím
                Color(0xFFC51162), // hồng đậm
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
        body: const Center(child: Text("Người dùng không tồn tại hoặc đã bị xóa")),
      );
    }

    // 1. Xác định xem có phải là Shop không
    bool isStore = false;
    if (widget.forceIndividual) {
      isStore = false; 
    } else {
      isStore = _sellerUser!.role == UserRole.seller || (_sellerUser!.storeName != null && _sellerUser!.storeName!.isNotEmpty);
    }
    
    // 2. 👇 LOGIC LẤY TÊN (SỬA LẠI CHỖ NÀY)
    // Mặc định lấy tên hiển thị cá nhân (displayName)
    String displayName = _sellerUser!.displayName;
    
    // Nếu rỗng quá thì ghi tạm là "Người dùng"
    if (displayName.isEmpty) displayName = "Người dùng";

    // Nếu là Shop VÀ có tên Shop -> Thì ưu tiên lấy tên Shop đè lên
    if (isStore && _sellerUser!.storeName != null && _sellerUser!.storeName!.trim().isNotEmpty) {
      displayName = _sellerUser!.storeName!;
    }

    // 3. Lấy Avatar (Shop thì lấy storeAva, cá nhân lấy photoUrl)
    String? avatarUrl;
    if (isStore && _sellerUser!.storeAva != null && _sellerUser!.storeAva!.isNotEmpty) {
      avatarUrl = _sellerUser!.storeAva;
    } else {
      avatarUrl = _sellerUser!.photoUrl;
    }

    final int followerCount = isStore ? _sellerUser!.storeFollowers : _sellerUser!.followers;

    // ... (Phần return Scaffold giữ nguyên như cũ)

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(isStore ? "Thông tin Cửa hàng" : "Trang cá nhân"),
        backgroundColor: isStore ? Colors.purple : Colors.white,
        foregroundColor: isStore ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- PHẦN HEADER THÔNG TIN ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isStore ? Colors.purple : Colors.grey[300]!, width: 3)
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Icon(isStore ? Icons.store : Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (isStore) ...[
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(5)),
                          child: const Text("Đối tác uy tín", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (_sellerUser!.address != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            Text(" ${_sellerUser!.address}", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                  ] else ...[
                     const Text("Thành viên cá nhân", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],

                  const SizedBox(height: 20),
                  
                  // 👇 THỐNG KÊ (Dùng biến displayCount)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStat("Người theo dõi", followerCount),
                      Container(height: 30, width: 1, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 30)),
                      _buildStat("Đang theo dõi", _sellerUser!.following),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 👇 NÚT FOLLOW (Thay đổi màu và chữ dựa trên _isFollowing)
                  if (_currentUserId != widget.userId)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            // Nếu đang follow thì màu xám, chưa follow thì màu Tím/Xanh
                            backgroundColor: _isFollowing ? Colors.grey[300] : (isStore ? Colors.purple : Colors.blue),
                            foregroundColor: _isFollowing ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: _isFollowing ? 0 : 2, // Đang follow thì bỏ bóng đổ cho chìm xuống
                          ),
                          child: Text(
                            _isFollowing ? "Đang theo dõi" : "Theo dõi", // Đổi chữ
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () { /* Gọi điện */ },
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text("Liên hệ"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // ... (Phần MÔ TẢ và DANH SÁCH XE giữ nguyên như cũ) ...
            if (isStore && _sellerUser!.description != null && _sellerUser!.description!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Giới thiệu cửa hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_sellerUser!.description!, style: TextStyle(color: Colors.grey[700], height: 1.4)),
                  ],
                ),
              ),

            // --- DANH SÁCH XE ĐANG BÁN ---
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tin đăng của ${isStore ? 'Cửa hàng' : 'người này'}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vehicles')
                         .where('ownerId', isEqualTo: widget.userId)
                         .where('status', isEqualTo: 'approved')
                         // 👇 THÊM ĐIỀU KIỆN LỌC NÀY
                         // Nếu đang xem Shop -> Chỉ hiện tin có storeName
                         // Nếu đang xem Cá nhân -> Chỉ hiện tin KHÔNG có storeName (hoặc null)
                         // .where('storeName', isNull: !isStore) // ⚠️ Lưu ý: Firestore query null hơi phức tạp
                         
                         // CÁCH ĐƠN GIẢN HƠN: Lọc ở phía Client (bên dưới)
                         .orderBy('createdAt', descending: true)
                         .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có tin đăng nào.")));
                      }
                      final allDocs = snapshot.data!.docs;
                       final filteredDocs = allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final hasStoreName = data['storeName'] != null && data['storeName'].toString().isNotEmpty;
                          
                          if (isStore) {
                            return hasStoreName; // Shop chỉ hiện tin Shop
                          } else {
                            return !hasStoreName; // Cá nhân chỉ hiện tin Cá nhân
                          }
                       }).toList();

                       if (filteredDocs.isEmpty) return const Text("Chưa có tin đăng nào.");
                      final docs = snapshot.data!.docs;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final vehicle = VehicleModel.fromMap(data, docs[index].id);
                          return VehicleCard(
                            vehicle: vehicle, 
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle)));
                            }
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}