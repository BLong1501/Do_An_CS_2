import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Dữ liệu Categories (Giữ nguyên)
  final List<String> categories = [
    'Xe máy', 'Ô tô', 'Xe đạp', 'Xe tải', 'Xe điện', 'Phụ tùng', 'Tàu thuyền'
  ];

  // 2. Dữ liệu Brands được phân loại rõ ràng (Map)
  final Map<String, List<String>> brandMapping = {
    'Xe máy': [
      'Honda', 'Yamaha', 'Suzuki', 'Piaggio', 'SYM', 'VinFast', 'Ducati', 'Kawasaki'
    ],
    'Ô tô': [
      'Toyota', 'Hyundai', 'Kia', 'Mazda', 'Ford', 'Honda', 'VinFast', 
      'Mercedes', 'BMW', 'Audi', 'Lexus', 'Mitsubishi'
    ],
    'Xe đạp': [
      'Asama', 'Giant', 'Martin', 'Thống Nhất', 'Galaxy'
    ],
    'Xe tải': [
      'Thaco', 'Hyundai', 'Isuzu', 'Hino', 'Dongfeng', 'Fuso', 'Kia', 'Jac','Howo'
    ],
    'Xe điện': [
      'VinFast', 'Pega', 'Yadea', 'Dat Bike'
    ]
  };

  final List<String> fuelTypes = ['Xăng', 'Dầu', 'Điện', 'Hybrid'];

  final List<String> locations = [
    'Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ', 'Nghệ An', 'Thanh Hóa','Huế'
  ];

  Future<void> seedData() async {
    print("⏳ Đang bắt đầu đẩy dữ liệu...");
    
    // Upload danh sách đơn giản
    await _uploadSimpleList('categories', categories);
    await _uploadSimpleList('fuel_types', fuelTypes);
    await _uploadSimpleList('locations', locations);

    // Upload Brands theo logic mới (Quan trọng)
    await _uploadBrands();
    
    print("✅ Đã khởi tạo dữ liệu thành công!");
  }

  // Hàm upload danh sách đơn giản (Categories, Locations...)
  Future<void> _uploadSimpleList(String collectionName, List<String> items) async {
    final batch = _db.batch();
    for (var item in items) {
      final docRef = _db.collection(collectionName).doc(item);
      batch.set(docRef, {
        'name': item,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Hàm xử lý logic Brand thông minh
  Future<void> _uploadBrands() async {
    final batch = _db.batch();

    // Duyệt qua từng loại xe trong Map
    for (var entry in brandMapping.entries) {
      String category = entry.key; // Ví dụ: "Xe máy"
      List<String> brands = entry.value; // Ví dụ: ["Honda", "Yamaha"...]

      for (var brandName in brands) {
        final docRef = _db.collection('brands').doc(brandName);
        
        // Dùng SetOptions(merge: true) để gộp dữ liệu
        // Ví dụ: Honda xuất hiện ở Xe máy và Ô tô -> Nó sẽ thêm cả 2 vào mảng 'types'
        batch.set(docRef, {
          'name': brandName,
          'types': FieldValue.arrayUnion([category]), // Thêm loại xe vào mảng
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }
}