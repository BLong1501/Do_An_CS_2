import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Lấy thông tin User hiện tại (ĐÃ CHUẨN)
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(firebaseUser.uid).get();
        
        if (doc.exists) {
          // Model mới của bạn đã xử lý tốt các trường thiếu bằng giá trị mặc định
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      return null;
    } catch (e) {
      print("Lỗi lấy dữ liệu user: $e");
      return null;
    }
  }

  // 2. Hàm Đăng ký (Cập nhật thêm tham số phone và address cho đầy đủ)
  // Mặc dù hiện tại AuthProvider đang tự xử lý, nhưng cập nhật ở đây để sau này dùng lại được
  Future<void> register({
    required String email, 
    required String password, 
    required String name,
    String? phone,    // Thêm số điện thoại
    String? address,  // Thêm địa chỉ
  }) async {
    // 1. Tạo tài khoản Auth
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    // 2. Tạo Model với đầy đủ thông tin mới
    UserModel newUser = UserModel(
      uid: credential.user!.uid, 
      email: email, 
      displayName: name,
      phoneNumber: phone,       // Lưu SĐT
      address: address,         // Lưu địa chỉ
      role: UserRole.user,
      isActive: true,
      isPendingUpgrade: false,
      favoritePostIds: [],
      createdAt: DateTime.now(),
      followers: 0, // Mặc định 0
      following: 0, // Mặc định 0
    );
    
    // 3. Lưu lên Firestore
    await _db.collection('users').doc(credential.user!.uid).set(newUser.toMap());
  }
}