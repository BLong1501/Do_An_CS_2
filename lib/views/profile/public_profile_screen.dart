import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/providers/chat_provider.dart';
import 'package:my_app/views/chat/chat_detail_screen.dart';
import 'package:my_app/views/profile/user_follow_list_screen.dart';
import 'package:my_app/views/seller/store_followers_screen.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';
import '../vehicle/vehicle_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final bool forceIndividual;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.forceIndividual = false,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isFollowing = false;
  bool _isLoading = true;
  UserModel? _sellerUser;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Biến này để hiển thị số lượng follow thay đổi ngay lập tức trên UI
  int _localFollowerCount = 0;
  int _localFollowingCount = 0; // Thêm biến để hiện số following động

  @override
  void initState() {
    super.initState();
    _fetchSellerInfo();
  }

  // 1. Lấy thông tin người bán
  Future<void> _fetchSellerInfo() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        final user = UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Xác định chế độ hiển thị (Shop hay Cá nhân)
        bool isStoreMode = false;

        if (widget.forceIndividual) {
          isStoreMode = false;
        } else {
          // Đổi || thành &&
          isStoreMode = user.role == UserRole.seller && 
              (user.storeName != null && user.storeName!.trim().isNotEmpty);
        }

        setState(() {
          _sellerUser = user;
          // Lấy đúng số follower dựa trên chế độ
          _localFollowerCount = isStoreMode ? user.storeFollowers : user.followers;
          // Lấy đúng số following dựa trên chế độ
          _localFollowingCount = isStoreMode ? user.storeFollowing : user.following;
        });

        // Đợi có thông tin user rồi mới check follow để biết check bảng nào
        await _checkIfFollowing(isStoreMode);
      }
    } catch (e) {
      print("Lỗi lấy thông tin: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Kiểm tra trạng thái Follow (ĐÃ SỬA CHUẨN)
  Future<void> _checkIfFollowing(bool isStoreTarget) async {
    if (_currentUserId.isEmpty) return;

    // QUAN TRỌNG: Quét đúng collection
    String collectionToCheck = isStoreTarget ? 'store_following' : 'following';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection(collectionToCheck)
        .doc(widget.userId)
        .get();

    if (mounted) {
      setState(() => _isFollowing = doc.exists);
    }
  }

  // 3. HÀM FOLLOW / UNFOLLOW (ĐÃ SỬA CHUẨN LOGIC)
  Future<void> _toggleFollow() async {
    if (_currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập!")));
      return;
    }
    if (_currentUserId == widget.userId) return;

    // A. Xác định xem đối phương là Shop hay Cá nhân
    bool isStoreTarget = false;
    if (widget.forceIndividual) {
      isStoreTarget = false;
    } else {
      // Đổi || thành &&
      isStoreTarget = _sellerUser!.role == UserRole.seller &&
          (_sellerUser!.storeName != null && _sellerUser!.storeName!.trim().isNotEmpty);
    }

    final bool originalState = _isFollowing;
    final int originalCount = _localFollowerCount;

    // B. Cập nhật UI ngay lập tức
    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _localFollowerCount += 1;
      } else {
        _localFollowerCount -= 1;
      }
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      final myUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);
      final targetUserRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      // C. Khai báo đúng các trường cần thao tác
      String myFollowingCollection = isStoreTarget ? 'store_following' : 'following';
      String targetFollowerCollection = isStoreTarget ? 'store_followers' : 'followers';
      
      // Chú ý: Cần khớp với field trong model UserModel của bạn
      String myCounterField = isStoreTarget ? 'storeFollowing' : 'following';
      String targetCounterField = isStoreTarget ? 'storeFollowers' : 'followers';

      // Reference
      final myFollowingRef = myUserRef.collection(myFollowingCollection).doc(widget.userId);
      final targetFollowerRef = targetUserRef.collection(targetFollowerCollection).doc(_currentUserId);

      if (!originalState) {
        // --- FOLLOW ---
        batch.set(myFollowingRef, {'createdAt': FieldValue.serverTimestamp()});
        batch.set(targetFollowerRef, {'createdAt': FieldValue.serverTimestamp()});

        batch.update(myUserRef, {myCounterField: FieldValue.increment(1)});
        batch.update(targetUserRef, {targetCounterField: FieldValue.increment(1)});
      } else {
        // --- UNFOLLOW ---
        batch.delete(myFollowingRef);
        batch.delete(targetFollowerRef);

        batch.update(myUserRef, {myCounterField: FieldValue.increment(-1)});
        batch.update(targetUserRef, {targetCounterField: FieldValue.increment(-1)});
      }

      await batch.commit();
    } catch (e) {
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_sellerUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Lỗi"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: const Center(
          child: Text("Người dùng không tồn tại hoặc đã bị xóa"),
        ),
      );
    }

   // 1. Xác định xem có phải là Shop không
    bool isStore = false;
    if (widget.forceIndividual) {
      isStore = false;
    } else {
      // Đổi || thành &&
      isStore = _sellerUser!.role == UserRole.seller &&
          (_sellerUser!.storeName != null && _sellerUser!.storeName!.trim().isNotEmpty);
    }

    // 2. Logic lấy tên
    String displayName = _sellerUser!.displayName;
    if (displayName.isEmpty) displayName = "Người dùng";

    if (isStore && _sellerUser!.storeName != null && _sellerUser!.storeName!.trim().isNotEmpty) {
      displayName = _sellerUser!.storeName!;
    }

    // 3. Lấy Avatar
    String? avatarUrl;
    if (isStore && _sellerUser!.storeAva != null && _sellerUser!.storeAva!.isNotEmpty) {
      avatarUrl = _sellerUser!.storeAva;
    } else {
      avatarUrl = _sellerUser!.photoUrl;
    }

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
            // --- HEADER ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isStore ? Colors.purple : Colors.grey[300]!, width: 3),
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
                  // 4. THỐNG KÊ (Follower / Following)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // NÚT: NGƯỜI THEO DÕI
                      _buildStat(
                        "Người theo dõi", 
                        _localFollowerCount,
                        onTap: () {
                          if (isStore) {
                            // Nếu là Shop -> Mở danh sách Follower của Shop
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreFollowersScreen(storeId: widget.userId),
                              ),
                            );
                          } else {
                            // Nếu là Cá nhân -> Mở danh sách Follower cá nhân (Tab 1)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserFollowListScreen(
                                  userId: widget.userId,
                                  initialTabIndex: 1, // 1 là Tab Người theo dõi
                                ),
                              ),
                            );
                          }
                        }
                      ),
                      
                      // CHỈ HIỆN "ĐANG THEO DÕI" NẾU LÀ CÁ NHÂN
                      if (!isStore) ...[
                        Container(
                          height: 30, 
                          width: 1, 
                          color: Colors.grey[300], 
                          margin: const EdgeInsets.symmetric(horizontal: 20)
                        ),
                        
                        // NÚT: ĐANG THEO DÕI
                        _buildStat(
                          "Đang theo dõi", 
                          _localFollowingCount,
                          onTap: () {
                            // Mở danh sách Đang theo dõi cá nhân (Tab 0)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserFollowListScreen(
                                  userId: widget.userId,
                                  initialTabIndex: 0, // 0 là Tab Đang theo dõi
                                ),
                              ),
                            );
                          }
                        ), 
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // CÁC NÚT HÀNH ĐỘNG
                  if (_currentUserId != widget.userId) ...[
                    if (_sellerUser!.role == UserRole.admin) ...[
                      const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text("Tài khoản Quản trị viên", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing ? Colors.grey[300] : (isStore ? Colors.purple : Colors.blue),
                                foregroundColor: _isFollowing ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: _isFollowing ? 0 : 2,
                              ),
                              child: Text(_isFollowing ? "Đang theo dõi" : "Theo dõi", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                side: const BorderSide(color: Colors.blue),
                              ),
                              icon: const Icon(Icons.message, size: 18, color: Colors.blue),
                              label: const Text("Liên hệ", style: TextStyle(color: Colors.blue)),
                              onPressed: () async {
                                if (_currentUserId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập!")));
                                  return;
                                }
                                showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
                                try {
                                  final QuerySnapshot query = await FirebaseFirestore.instance.collection('chat_rooms')
                                      .where('users', arrayContains: _currentUserId)
                                      .orderBy('lastMessageTime', descending: true)
                                      .get();

                                  DocumentSnapshot? existingRoom;
                                  for (var doc in query.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final List<dynamic> users = data['users'] ?? [];
                                    if (users.contains(widget.userId)) {
                                      existingRoom = doc;
                                      break;
                                    }
                                  }
                                  Navigator.pop(context);

                                  String targetChatRoomId;
                                  String targetVehicleId;
                                  String targetVehicleTitle;

                                  if (existingRoom != null) {
                                    final data = existingRoom.data() as Map<String, dynamic>;
                                    targetChatRoomId = existingRoom.id;
                                    targetVehicleId = data['vehicleId'] ?? 'unknown';
                                    targetVehicleTitle = data['vehicleTitle'] ?? 'Tin nhắn cũ';
                                  } else {
                                    const String generalTopicId = 'general_inquiry';
                                    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                                    targetChatRoomId = chatProvider.getChatRoomId(_currentUserId, widget.userId, generalTopicId);
                                    targetVehicleId = generalTopicId;
                                    targetVehicleTitle = "Trao đổi chung";
                                  }

                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(
                                    chatRoomId: targetChatRoomId,
                                    receiverId: widget.userId,
                                    receiverName: displayName,
                                    vehicleId: targetVehicleId,
                                    vehicleTitle: targetVehicleTitle,
                                    receiverAvatar: avatarUrl,
                                  )));
                                } catch (e) {
                                  Navigator.pop(context);
                                  print("Lỗi tìm phòng chat: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // --- GIỚI THIỆU CỬA HÀNG ---
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

            // --- DANH SÁCH XE ---
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tin đăng của ${isStore ? 'Cửa hàng' : 'người này'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vehicles')
                        .where('ownerId', isEqualTo: widget.userId)
                        .where('status', isEqualTo: 'approved')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có tin đăng nào.")));
                      }
                      
                      final allDocs = snapshot.data!.docs;
                      final filteredDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final hasStoreName = data['storeName'] != null && data['storeName'].toString().trim().isNotEmpty;
                        return isStore ? hasStoreName : !hasStoreName;
                      }).toList();

                      if (filteredDocs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có tin đăng nào.")));

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data() as Map<String, dynamic>;
                          final vehicle = VehicleModel.fromMap(data, filteredDocs[index].id);
                          return VehicleCard(
                            vehicle: vehicle,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle))),
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

 // Hàm đã được thêm tham số {VoidCallback? onTap} và bọc bằng InkWell
  Widget _buildStat(String label, int count, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              "$count", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: const TextStyle(color: Colors.grey, fontSize: 13)
            ),
          ],
        ),
      ),
    );
  }
}