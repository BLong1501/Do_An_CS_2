import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedType = 'Góp ý tính năng'; // Giá trị mặc định
  bool _isSubmitting = false;

  final List<String> _feedbackTypes = [
    'Góp ý tính năng',
    'Báo lỗi (Bug)',
    'Góp ý giao diện',
    'Tố cáo người dùng khác',
    'Khác'
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập nội dung đóng góp."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
         throw Exception("Bạn chưa đăng nhập!");
      }

      // Lấy thêm thông tin User từ Firestore để đính kèm vào feedback
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      
      String userName = "Người dùng ẩn danh";
      String userRole = "user";
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        // Dựa vào UserModel, ưu tiên storeName nếu là Seller, nếu không lấy displayName
        userName = userData['storeName'] ?? userData['displayName'] ?? 'Người dùng';
        userRole = userData['role'] ?? 'user';
      }

      // Lưu dữ liệu vào collection 'feedbacks'
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'userId': currentUser.uid,
        'userEmail': currentUser.email ?? 'Không có email',
        'userName': userName,
        'role': userRole,
        'type': _selectedType,
        'content': _contentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Lưu dưới dạng Timestamp chuẩn của Firebase
        'isRead': false, // Trạng thái Admin chưa đọc
      });

      if (mounted) {
        Navigator.pop(context); // Đóng trang feedback sau khi gửi thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cảm ơn bạn đã đóng góp ý kiến!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi gửi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền sáng nhẹ
      appBar: AppBar(
        title: const Text(
          "Đóng góp ý kiến", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFFC51162)], // Màu Gradient đồng bộ với App
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phần tiêu đề (Header)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.feedback_outlined, size: 60, color: const Color(0xFF5D3FD3).withOpacity(0.8)),
                    const SizedBox(height: 12),
                    const Text(
                      "Chúng tôi luôn lắng nghe bạn!",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Mọi đóng góp của bạn đều giúp ứng dụng hoàn thiện hơn mỗi ngày.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Chọn thể loại đóng góp
              const Text(
                "Phân loại:", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                  ]
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedType,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    items: _feedbackTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) setState(() => _selectedType = newValue);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Nội dung chi tiết
              const Text(
                "Nội dung chi tiết:", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                  ]
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: 7, // Hộp text to cho dễ viết
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: "Hãy chia sẻ suy nghĩ hoặc vấn đề bạn gặp phải...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5D3FD3), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Nút Gửi
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC51162), // Màu hồng đậm
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 25, width: 25,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Gửi ý kiến", 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}