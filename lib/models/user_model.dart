enum UserRole { user, seller, admin }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;    // Cần để liên hệ mua bán
  final String? photoUrl;       // Ảnh đại diện
  final UserRole role;
  final bool isActive;          // Để Admin khóa/mở tài khoản
  final bool isPendingUpgrade;  // Đang chờ duyệt lên Seller
  final String? address;        // Khu vực của người dùng
  final List<String> favoritePostIds; // Danh sách ID các xe đã thả tim
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.role = UserRole.user,
    this.isActive = true,
    this.isPendingUpgrade = false,
    this.address,
    this.favoritePostIds = const [],
    required this.createdAt,
    this.lastLoginAt,
  });

  // Chuyển sang Map để lưu lên Firestore
  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'photoUrl': photoUrl,
        'role': role.name,
        'isActive': isActive,
        'isPendingUpgrade': isPendingUpgrade,
        'address': address,
        'favoritePostIds': favoritePostIds,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };

  // Đọc dữ liệu từ Firestore
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
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
    );
  }
}