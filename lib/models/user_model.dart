enum UserRole { user, seller, admin }

class UserModel {
  final String uid;
  final String email; // Dùng để đăng nhập (Gmail)
  final String displayName; // Tên đầy đủ (Lấy từ Google, VD: Nguyễn Văn A)
  final String? username; // [MỚI] Biệt danh/Tên người dùng (VD: nguyenvana99)

  final String? phoneNumber;
  final String? photoUrl;
  final UserRole role;
  final bool isActive;
  final bool isPendingUpgrade;
  final String? address;
  final List<String> favoritePostIds;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  // 👇 [MỚI 1] THÊM 2 BIẾN ĐẾM
  final int followers; // Số người đang theo dõi mình
  final int following; // Số người mình đang theo dõi
  final String? storeName;   // Tên cửa hàng (Nếu có dữ liệu này => Đã tạo shop)
  final String? taxCode;     // Mã số thuế
  final String? description; // Mô tả cửa hàng
  final String? storeAva;
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.username, // Thêm vào đây (có thể null nếu user chưa đặt)
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
    this.storeAva
  });

  // Lưu lên Firestore
  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'username': username, // Lưu biệt danh lên server
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
    'storeName': storeName,
        'taxCode': taxCode,
        'description': description,
        'storeAva': storeAva, 
  };

  // Đọc về App
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',

      username: data['username'], // Đọc biệt danh về
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
      storeName: data['storeName'],
      taxCode: data['taxCode'],
      description: data['description'],
      storeAva: data['storeAva'],
    );
  }
  // 👇 THÊM HÀM NÀY VÀO CUỐI CLASS USERMODEL
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
      // Các trường Store
      storeName: storeName ?? this.storeName,
      taxCode: taxCode ?? this.taxCode,
      description: description ?? this.description,
      storeAva: storeAva ?? this.storeAva,
    );
  }
}
