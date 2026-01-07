import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_app/views/admin/admin_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; 
import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart'; // 1. THÊM IMPORT NÀY
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider; 
import 'views/home/home_screen.dart';           
import 'views/auth/login_screen.dart';         

// // ... các import ...
// import 'views/admin/admin_screen.dart'; // Import thêm màn hình Admin

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()), // 2. KHAI BÁO THÊM Ở ĐÂY
      ],
      child: const MyApp(),
    ),
  );
}
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Chợ Tốt Phương Tiện',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange), // Dùng Material 3 chuẩn
//         useMaterial3: true
//       ),
//       home: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }
//           if (snapshot.hasData) {
//             // 3. SỬA LỖI GỌI PROVIDER: Dùng WidgetsBinding để tránh lỗi "set state during build"
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               Provider.of<AuthProvider>(context, listen: false).fetchUserData();
//             });
//             return const HomeScreen();
//           } 
//           return const LoginScreen();
//         },
//       ),
//     );
//   }
// }



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // ... các config theme ...
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasData) {
            // Khi đã có User từ Firebase Auth, ta cần lấy thêm Role từ Firestore
            // Dùng FutureBuilder để chờ lấy Role
            return FutureBuilder(
              future: Provider.of<AuthProvider>(context, listen: false).fetchUserData(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  // Màn hình chờ (Splash Screen) trong lúc tải Role
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                // Lấy User từ Provider ra để check Role
                final userModel = Provider.of<AuthProvider>(context, listen: false).user;

                if (userModel?.role.name == 'admin') {
                  return const AdminScreen(); // ✅ Vào Admin
                } else {
                  return const HomeScreen();  // ✅ Vào Home
                }
              },
            );
          }
          
          // Chưa đăng nhập thì về trang Login
          return const LoginScreen();
        },
      ),
    );
  }
}