import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Màu nền nhẹ nhàng
      appBar: AppBar(
        title: const Text(
          "Trợ giúp & Hỗ trợ",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFFC51162)], // Gradient giống ProfileScreen
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Icon hoặc Logo (Thay thế bằng ảnh nếu bạn có)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                size: 80,
                color: Color(0xFF5D3FD3),
              ),
            ),
            const SizedBox(height: 20),
            
            // Tiêu đề
            const Text(
              "Thông tin liên hệ Hỗ trợ",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Nếu bạn gặp bất kỳ vấn đề gì trong quá trình sử dụng ứng dụng, vui lòng liên hệ trực tiếp với người phát triển (Developer) theo thông tin bên dưới.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Card chứa thông tin liên hệ
            Card(
              elevation: 4,
              shadowColor: Colors.purple.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildContactRow(
                      icon: Icons.person,
                      title: "Người phát triển",
                      value: "Trần Bảo Long",
                      iconColor: Colors.blue,
                    ),
                    const Divider(height: 30),
                    _buildContactRow(
                      icon: Icons.phone_android,
                      title: "Số điện thoại",
                      value: "0344907168",
                      iconColor: Colors.green,
                    ),
                    const Divider(height: 30),
                    _buildContactRow(
                      icon: Icons.email,
                      title: "Email",
                      value: "tranbaolong5b@gmail.com",
                      iconColor: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Text(
              "Mọi thông tin đóng góp hoặc yêu cầu hỗ trợ, xin vui lòng liên hệ với tôi. Cảm ơn bạn đã sử dụng ứng dụng!",
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget con để vẽ từng dòng thông tin
  Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}