import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/providers/chat_provider.dart';
import 'package:my_app/views/admin/admin_screen.dart';
import 'package:provider/provider.dart';

// Import các provider và screen
import 'package:my_app/providers/auth_provider.dart' as my_auth;
import 'package:my_app/providers/vehicle_provider.dart';
import 'package:my_app/views/auth/login_screen.dart';
import 'package:my_app/views/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 👇 1. SỬA ĐOẠN NÀY ĐỂ KÍCH HOẠT REAL-TIME KHI AUTO LOGIN
        ChangeNotifierProvider(
          create: (_) {
            final authProvider = my_auth.AuthProvider();
            
            // Kiểm tra: Nếu Firebase đã lưu phiên đăng nhập từ trước
            if (FirebaseAuth.instance.currentUser != null) {
              print("🚀 App khởi động: User đã đăng nhập -> Bắt đầu lắng nghe Real-time");
              
              // Gọi hàm này để AuthProvider bắt đầu nghe thay đổi từ Firestore ngay lập tức
              authProvider.startListeningToUserData();
            }
            
            return authProvider;
          },
        ),
        
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Xe Giá Tốt',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color.fromARGB(255, 48, 90, 204),
        ),
        // 👇 2. Logic điều hướng (Giữ nguyên vì nó rất tốt)
       // Thay thế đoạn home: StreamBuilder... bằng đoạn này:
home: Consumer<my_auth.AuthProvider>(
  builder: (context, authProvider, _) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Đang kiểm tra Auth Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Chưa đăng nhập -> Về trang Login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 3. Đã đăng nhập Firebase -> Kiểm tra Role trong Firestore
        // Nếu AuthProvider chưa load xong user data -> Hiện loading
        if (authProvider.user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 4. Đã có data User -> Điều hướng theo Role
        if (authProvider.user!.role == UserRole.admin) { // Sửa lại đường dẫn UserRole cho đúng file model của bạn
          return const AdminScreen();
        } else {
          return const MainScreen(); // User hoặc Seller vào đây
        }
      },
    );
  },
),
      ),
    );
  }
}