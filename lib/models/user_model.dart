import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, seller, admin }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? username;
  final String? phoneNumber;
  final String? photoUrl;
  final UserRole role;
  final bool isActive;
  final bool isPendingUpgrade;
  
  // 👇 THÊM 2 BIẾN ÁN PHẠT Ở ĐÂY
  final bool isBanned; 
  final bool canPost;

  final String? address;
  final List<String> favoritePostIds;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // Chỉ số cá nhân
  final int followers; 
  final int following;

  // [THÔNG TIN CỬA HÀNG]
  final String? storeName;
  final String? taxCode;
  final String? description;
  final String? storeAva;
  final int storeFollowers; 
  final int storeFollowing;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.username,
    this.phoneNumber,
    this.photoUrl,
    this.role = UserRole.user,
    this.isActive = true,
    this.isPendingUpgrade = false,
    
    // 👇 Khởi tạo giá trị mặc định cho user mới (Không bị ban, Được phép đăng bài)
    this.isBanned = false,
    this.canPost = true,

    this.address,
    this.favoritePostIds = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.followers = 0,
    this.following = 0,
    this.storeName,
    this.taxCode,
    this.description,
    this.storeAva,
    this.storeFollowers = 0, 
    this.storeFollowing = 0,
  });

  // Lưu lên Firestore
  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'username': username,
    'phoneNumber': phoneNumber,
    'photoUrl': photoUrl,
    'role': role.name,
    'isActive': isActive,
    'isPendingUpgrade': isPendingUpgrade,
    
    // 👇 Lưu lên Firebase
    'isBanned': isBanned,
    'canPost': canPost,

    'address': address,
    'favoritePostIds': favoritePostIds,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'followers': followers,
    'following': following,
    'storeName': storeName,
    'taxCode': taxCode,
    'description': description,
    'storeAva': storeAva,
    'storeFollowers': storeFollowers,
    'storeFollowing': storeFollowing,
  };

  // 👇 HÀM XỬ LÝ NGÀY THÁNG AN TOÀN (QUAN TRỌNG)
  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now(); // Nếu null thì lấy giờ hiện tại
    if (val is Timestamp) return val.toDate(); // ✅ Xử lý nếu là Timestamp (từ Admin tạo)
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now(); // ✅ Xử lý nếu là String
    return DateTime.now(); // Fallback
  }

  // Đọc từ Firestore về App
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      username: data['username'],
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.user,
      ),
      isActive: data['isActive'] ?? true,
      isPendingUpgrade: data['isPendingUpgrade'] ?? false,
      
      // 👇 Đọc từ Firebase về
      
      isBanned: data['isBanned'] == true, // Nếu null hoặc khác true -> false
      canPost: data['canPost'] != false,

      address: data['address'],
      favoritePostIds: List<String>.from(data['favoritePostIds'] ?? []),
      createdAt: _parseDate(data['createdAt']),
      lastLoginAt: data['lastLoginAt'] != null ? _parseDate(data['lastLoginAt']) : null,
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
      storeName: data['storeName'],
      taxCode: data['taxCode'],
      description: data['description'],
      storeAva: data['storeAva'],
      storeFollowers: data['storeFollowers'] ?? 0,
      storeFollowing: data['storeFollowing'] ?? 0,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? phoneNumber,
    String? photoUrl,
    UserRole? role,
    bool? isActive,
    bool? isPendingUpgrade,
    
    // 👇 Thêm vào tham số copyWith
    bool? isBanned,
    bool? canPost,

    String? address,
    List<String>? favoritePostIds,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? followers,
    int? following,
    String? storeName,
    String? taxCode,
    String? description,
    String? storeAva,
    int? storeFollowers,
    int? storeFollowing,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isPendingUpgrade: isPendingUpgrade ?? this.isPendingUpgrade,
      
      // 👇 Gán giá trị mới nếu có
      isBanned: isBanned ?? this.isBanned,
      canPost: canPost ?? this.canPost,

      address: address ?? this.address,
      favoritePostIds: favoritePostIds ?? this.favoritePostIds,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      storeName: storeName ?? this.storeName,
      taxCode: taxCode ?? this.taxCode,
      description: description ?? this.description,
      storeAva: storeAva ?? this.storeAva,
      storeFollowers: storeFollowers ?? this.storeFollowers,
      storeFollowing: storeFollowing ?? this.storeFollowing,
    );
  }
}