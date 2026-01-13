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
  final String? address;
  final List<String> favoritePostIds;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // Chỉ số cá nhân
  final int followers; // Follow cá nhân (bạn bè)
  final int following;

  // 👇 [THÔNG TIN CỬA HÀNG]
  final String? storeName;
  final String? taxCode;
  final String? description;
  final String? storeAva;
  final int storeFollowers; // 👈 [MỚI] Số người theo dõi cửa hàng

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
    this.storeFollowers = 0, // 👈 [MỚI] Mặc định là 0
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
    'address': address,
    'favoritePostIds': favoritePostIds,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'followers': followers,
    'following': following,
    
    // Các trường của Shop
    'storeName': storeName,
    'taxCode': taxCode,
    'description': description,
    'storeAva': storeAva,
    'storeFollowers': storeFollowers, // 👈 [MỚI] Lưu lên DB
  };

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
      address: data['address'],
      favoritePostIds: List<String>.from(data['favoritePostIds'] ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.parse(data['lastLoginAt'])
          : null,
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
      
      // Đọc thông tin Shop
      storeName: data['storeName'],
      taxCode: data['taxCode'],
      description: data['description'],
      storeAva: data['storeAva'],
      storeFollowers: data['storeFollowers'] ?? 0, // 👈 [MỚI] Đọc về (có default)
    );
  }

  // Hàm copyWith (Hỗ trợ cập nhật nhanh)
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
    int? storeFollowers, // 👈 [MỚI] Thêm tham số
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
      address: address ?? this.address,
      favoritePostIds: favoritePostIds ?? this.favoritePostIds,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      
      // Update Shop Info
      storeName: storeName ?? this.storeName,
      taxCode: taxCode ?? this.taxCode,
      description: description ?? this.description,
      storeAva: storeAva ?? this.storeAva,
      storeFollowers: storeFollowers ?? this.storeFollowers, // 👈 [MỚI] Update giá trị
    );
  }
}