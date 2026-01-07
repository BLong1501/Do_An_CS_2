import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _user;
  UserModel? get user => _user;

  Future<void> fetchUserData() async {
    _user = await _authRepo.getCurrentUserData();
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _user = null; 
    notifyListeners();
  }

// Thêm tham số phone và address vào hàm
  Future<void> register(String email, String password, String name, String phone, String address) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Tạo tài khoản Authentication
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? firebaseUser = cred.user;
      
      if (firebaseUser != null) {
        // Cập nhật tên hiển thị cho Auth (để tiện hiển thị nhanh)
        await firebaseUser.updateDisplayName(name);

        // 2. Tạo Model User đầy đủ thông tin
        UserModel newUser = UserModel(
          uid: firebaseUser.uid,
          email: email,
          displayName: name,
          phoneNumber: phone, // Lưu số điện thoại
          address: address,   // Lưu địa chỉ
          role: UserRole.user, // Mặc định là user thường
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          // Các trường khác để mặc định trong Model
        );

        // 3. Lưu vào Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toMap());
            
        // 4. Cập nhật biến _user trong app
        _user = newUser;
      }
    } catch (e) {
      rethrow; // Ném lỗi ra để màn hình Đăng ký bắt được và hiện thông báo
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      await fetchUserData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Hàm gửi email reset mật khẩu (Logic thuần túy)
  Future<void> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      // Ném lỗi ra để bên UI bắt được và hiện thông báo
      throw e;
    }
  }
  // Hàm gửi yêu cầu nâng cấp lên Seller
  Future<void> requestUpgradeToSeller() async {
    if (_user == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Cập nhật Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'isPendingUpgrade': true});

      // 2. Cập nhật Model cục bộ (để UI đổi trạng thái ngay)
      // Lưu ý: Copy biến _user cũ và thay đổi giá trị isPendingUpgrade
      // (Cách này hơi thủ công, nhưng nhanh gọn)
      await fetchUserData(); // Load lại data mới nhất từ server cho chắc ăn
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Hàm gửi form đăng ký Seller (Kèm ảnh CCCD)
  Future<void> submitSellerRequest({
    required String fullName,
    required String citizenId, // Số CCCD
    required String address,
    required String storeName,
    required File? frontImage, // Ảnh mặt trước
    required File? backImage,  // Ảnh mặt sau
  }) async {
    if (_user == null) return;
    if (frontImage == null || backImage == null) throw Exception("Vui lòng chọn đủ ảnh CCCD");

    _isLoading = true;
    notifyListeners();

    try {
      String uid = _user!.uid;

      // 1. Upload ảnh lên Firebase Storage (SỬA ĐOẠN NÀY)
      final storageRef = FirebaseStorage.instance.ref().child('seller_requests/$uid');
      
      // --- Upload mặt trước ---
      final frontRef = storageRef.child('front.jpg');
      UploadTask uploadTaskFront = frontRef.putFile(frontImage); // Tạo task upload
      TaskSnapshot snapshotFront = await uploadTaskFront; // Đợi task hoàn thành 100%
      final String frontUrl = await snapshotFront.ref.getDownloadURL(); // Lấy link từ snapshot

      // --- Upload mặt sau ---
      final backRef = storageRef.child('back.jpg');
      UploadTask uploadTaskBack = backRef.putFile(backImage);
      TaskSnapshot snapshotBack = await uploadTaskBack;
      final String backUrl = await snapshotBack.ref.getDownloadURL();

      // 2. Lưu thông tin vào Firestore (Collection riêng: seller_requests)
      await FirebaseFirestore.instance.collection('seller_requests').doc(uid).set({
        'uid': uid,
        'email': _user!.email,
        'phoneNumber': _user!.phoneNumber,
        'fullName': fullName,
        'citizenId': citizenId,
        'address': address,
        'storeName': storeName,
        'frontIdUrl': frontUrl,
        'backIdUrl': backUrl,
        'status': 'pending', // Trạng thái chờ duyệt
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // 3. Cập nhật trạng thái user để UI hiển thị "Đang chờ"
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isPendingUpgrade': true
      });
      
      // Load lại user để cập nhật UI
      await fetchUserData();

    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}