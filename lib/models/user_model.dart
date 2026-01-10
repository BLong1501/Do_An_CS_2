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
    );
  }
}
