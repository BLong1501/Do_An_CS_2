import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

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
}