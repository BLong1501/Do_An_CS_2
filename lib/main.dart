import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart'; // 1. Bỏ comment dòng này
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Import các provider và screen
import 'package:my_app/providers/auth_provider.dart' as my_auth;
import 'package:my_app/providers/vehicle_provider.dart';
import 'package:my_app/views/auth/login_screen.dart';
import 'package:my_app/views/main_screen.dart';

// 👇 2. ĐÂY LÀ PHẦN QUAN TRỌNG BẠN ĐANG THIẾU
void main() async {
  // Đảm bảo Flutter Engine đã sẵn sàng trước khi gọi code bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp();
  
  // Chạy ứng dụng
  runApp(const MyApp());
}
// ------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => my_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Xe Giá Tốt',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color.fromARGB(255, 48, 90, 204),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasData) {
              return const MainScreen(); 
            }
            
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}