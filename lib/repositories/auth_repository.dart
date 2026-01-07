import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  
  // HÀM ĐANG THIẾU CỦA BẠN ĐÂY:
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Lấy document từ collection 'users' dựa trên UID của người dùng
        DocumentSnapshot doc = await _db.collection('users').doc(firebaseUser.uid).get();
        
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      return null;
    } catch (e) {
      print("Lỗi lấy dữ liệu user: $e");
      return null;
    }
  }

  // Hàm register (đã có từ trước)
  // Hàm register cập nhật cho UserModel mới
  Future<void> register(String email, String password, String name) async {
    // 1. Tạo tài khoản trên Firebase Auth
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    // 2. Tạo đối tượng UserModel với đầy đủ các trường mới
    UserModel newUser = UserModel(
      uid: credential.user!.uid, 
      email: email, 
      displayName: name,
      role: UserRole.user,          // Mặc định là người dùng thường
      isActive: true,               // Mặc định tài khoản được hoạt động
      isPendingUpgrade: false,      // Chưa gửi yêu cầu nâng cấp
      favoritePostIds: [],          // Danh sách yêu thích trống
      createdAt: DateTime.now(),    // Ngày tạo là hiện tại
    );
    
    // 3. Lưu toàn bộ thông tin lên Firestore
    await _db.collection('users').doc(credential.user!.uid).set(newUser.toMap());
  
}

}